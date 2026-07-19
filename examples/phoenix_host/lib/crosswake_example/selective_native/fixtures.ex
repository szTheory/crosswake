defmodule CrosswakeExample.SelectiveNative.Fixtures do
  alias CrosswakeExample.Repo
  alias CrosswakeExample.SelectiveNative.Claim
  alias CrosswakeExample.SelectiveNative.Claims
  alias CrosswakeExample.SelectiveNative.Submission

  @claims [
    %{title: "Broken windshield", status: "pending"},
    %{title: "Hail damage", status: "pending"}
  ]

  def seed do
    {:ok, counts} =
      Repo.transaction(fn ->
        Repo.delete_all(Submission)
        Repo.delete_all(Claim)

        Enum.each(@claims, fn attrs ->
          {:ok, _claim} = Claims.create_claim(attrs)
        end)

        %{claims: length(@claims), submissions: 0}
      end)

    counts
  end

  def digest_components do
    @claims
    |> Enum.sort_by(& &1.title)
    |> Enum.map(&"field_service_native_pressure.claim:#{&1.title}:#{&1.status}")
  end
end
