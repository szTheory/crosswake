ExUnit.start()

unless System.get_env("MIX_INCLUDE_RULESTEAD") == "1" do
  ExUnit.configure(exclude: [advisory_only: true])
end
