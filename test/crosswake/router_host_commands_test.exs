defmodule Crosswake.RouterHostCommandsTest do
  use ExUnit.Case, async: true

  @file_name "host_commands_router.exs"

  defmodule Helper do
    def all, do: [{"host.review.camera.scan", "1.1.0"}, {"host.lesson.audio.play", "1.0.0"}]
  end

  defp module_name, do: "Crosswake.HostCommandsThrowaway#{System.unique_integer([:positive])}"

  # Compiles a throwaway router whose body starts on line 3 of @file_name.
  defp compile_router(
         body,
         header \\ "import Crosswake.Router, except: [get: 4, live: 4], warn: false"
       ) do
    name = module_name()
    source = "defmodule #{name} do\n  #{header}\n#{body}\nend\n"
    Code.compile_string(source, @file_name)
    Module.concat([name])
  end

  defp compile_error(
         body,
         header \\ "import Crosswake.Router, except: [get: 4, live: 4], warn: false"
       ) do
    assert_raise CompileError, fn -> compile_router(body, header) end
  end

  defp declare(list_source), do: "  crosswake_host_commands #{list_source}"

  test "duplicate id raises at the declaring line wherever it sits" do
    for list <- [
          ~s([{"host.a.b.c", "1.0.0"}, {"host.x.y.z", "1.0.0"}, {"host.a.b.c", "1.0.0"}]),
          ~s([{"host.a.b.c", "1.0.0"}, {"host.a.b.c", "1.0.0"}, {"host.x.y.z", "1.0.0"}])
        ] do
      error = compile_error(declare(list))
      assert error.file =~ @file_name
      assert error.line == 3
      assert error.description =~ "more than once"
    end
  end

  test "versions that are not strict three-part SemVer are rejected" do
    for version <- ["1.0", "v1.0.0", "1.0.0.0", "latest"] do
      error = compile_error(declare(~s([{"host.a.b.c", "#{version}"}])))
      assert error.description =~ "strict three-part SemVer"
    end
  end

  test "versions outside ^1.0.0 are rejected and 1.x.y compiles" do
    for version <- ["2.0.0", "9.0.0", "0.9.0"] do
      error = compile_error(declare(~s([{"host.a.b.c", "#{version}"}])))
      assert error.description =~ "^1.0.0"
    end

    for version <- ["1.0.0", "1.4.2"] do
      mod = compile_router(declare(~s([{"host.a.b.c", "#{version}"}])))
      assert mod.__crosswake_host_commands__() == [{"host.a.b.c", version}]
    end
  end

  test "malformed or reserved names are rejected" do
    for name <- ["host.lesson", "host.a.b.c.d", "host.Lesson.play.now", "host.lesson.*"] do
      error = compile_error(declare(~s([{"#{name}", "1.0.0"}])))
      assert error.description =~ "host.<namespace>.<action>"
    end

    error = compile_error(declare(~s([{"host.crosswake.audio.play", "1.0.0"}])))
    assert error.description =~ "reserved prefix"
  end

  test "two declarations in one module raise" do
    error =
      compile_error(
        declare(~s([{"host.a.b.c", "1.0.0"}])) <> "\n" <> declare(~s([{"host.x.y.z", "1.0.0"}]))
      )

    assert error.line == 4
    assert error.description =~ "already declared"
  end

  test "a non-list value and a non-tuple entry raise" do
    assert compile_error(declare(~s("host.a.b.c"))).description =~ "expected a list"
    assert compile_error(declare(~s(["host.a.b.c"]))).description =~ "{name, version} tuple"
    assert compile_error(declare(~s([{"host.a.b.c", 1}]))).description =~ "{name, version} tuple"
  end

  test "an empty registry defines __crosswake_host_commands__/0 returning []" do
    assert compile_router(declare("[]")).__crosswake_host_commands__() == []
  end

  test "a helper function returning the list compiles to the sorted list" do
    mod = compile_router(declare("Crosswake.RouterHostCommandsTest.Helper.all()"))

    assert mod.__crosswake_host_commands__() == [
             {"host.lesson.audio.play", "1.0.0"},
             {"host.review.camera.scan", "1.1.0"}
           ]
  end

  test "the use option and the macro form produce equal output" do
    list = ~s([{"host.review.camera.scan", "1.1.0"}, {"host.lesson.audio.play", "1.0.0"}])

    macro = compile_router(declare(list), "use Crosswake.Router")
    sugar = compile_router("", "use Crosswake.Router, host_commands: #{list}")

    assert macro.__crosswake_host_commands__() == sugar.__crosswake_host_commands__()
  end

  test "the use option reports errors at the use line" do
    name = module_name()

    source =
      "defmodule #{name} do\n  use Crosswake.Router, host_commands: [{\"host.a.b.c\", \"2.0.0\"}]\nend\n"

    error = assert_raise CompileError, fn -> Code.compile_string(source, @file_name) end
    assert error.line == 2
  end

  test "an import-style router without use can call crosswake_host_commands" do
    mod = compile_router(declare(~s([{"host.a.b.c", "1.0.0"}])))
    assert mod.__crosswake_host_commands__() == [{"host.a.b.c", "1.0.0"}]
  end
end
