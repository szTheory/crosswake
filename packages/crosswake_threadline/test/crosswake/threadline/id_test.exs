defmodule Crosswake.Threadline.IdTest do
  use ExUnit.Case, async: true

  alias Crosswake.Threadline.Id

  test "generate/0 returns a String of exactly 36 characters" do
    id = Id.generate()
    assert is_binary(id)
    assert String.length(id) == 36
  end

  test "generate/0 matches RFC-4122 v4 UUID format" do
    id = Id.generate()
    assert id =~ ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
  end

  test "generate/0 produces unique values" do
    ids = Enum.map(1..100, fn _ -> Id.generate() end)
    assert length(Enum.uniq(ids)) == 100
  end
end
