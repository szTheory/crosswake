defmodule Crosswake.Proof.Phase174MatrixInstallerContractTest do
  use ExUnit.Case, async: true

  @script "script/verify_companion_cleanroom.sh"
  @installer ~S(if ! "${RUNTIME[@]}" mix crosswake.install --router lib/clean_room_host_web/router.ex; then)
  @doctor ~S("${RUNTIME[@]}" mix crosswake.doctor --router CleanRoomHostWeb.Router)
  @compile ~S("${RUNTIME[@]}" mix compile --warnings-as-errors >/dev/null || matrix_fail)

  @tag :baseline_positive
  test "the shared matrix runs the real installer and recompiles before doctor" do
    assert :ok == validate_matrix(File.read!(@script))
  end

  test "omitting the matrix installer fails independently of the legacy installer" do
    source = File.read!(@script)
    changed = String.replace(source, @installer, "true", global: false)
    refute changed == source
    assert {:error, :installer_missing} == validate_matrix(changed)
  end

  test "the legacy router cannot substitute for the generated matrix router" do
    source = File.read!(@script)

    changed =
      String.replace(
        source,
        "lib/clean_room_host_web/router.ex; then",
        "lib/clean_room_host/router.ex; then",
        global: false
      )

    refute changed == source
    assert {:error, :installer_missing} == validate_matrix(changed)
  end

  test "installer success cannot precede a swallowed installer failure" do
    source = File.read!(@script)

    changed =
      String.replace(
        source,
        @installer <> "\n          matrix_fail",
        @installer <> "\n          true",
        global: false
      )

    refute changed == source
    assert {:error, :installer_failure_swallowed} == validate_matrix(changed)
  end

  defp validate_matrix(source) do
    matrix = source |> String.split("\nSCRIPT_DIR=", parts: 2) |> hd()

    loop =
      matrix
      |> String.split("for MATRIX_PROFILE in rulestead rindle sigra chimeway threadline; do",
        parts: 2
      )
      |> List.last()

    install = offset(loop, @installer)
    doctor = offset(loop, @doctor)

    cond do
      install == nil ->
        {:error, :installer_missing}

      doctor == nil or install >= doctor ->
        {:error, :installer_order}

      not String.contains?(loop, @installer <> "\n          matrix_fail\n        fi") ->
        {:error, :installer_failure_swallowed}

      not String.contains?(String.slice(loop, install..(doctor - 1)), @compile) ->
        {:error, :recompile_missing}

      true ->
        :ok
    end
  end

  defp offset(source, needle) do
    case :binary.match(source, needle) do
      {at, _length} -> at
      :nomatch -> nil
    end
  end
end
