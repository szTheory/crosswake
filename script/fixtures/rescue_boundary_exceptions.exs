# Reviewed arbitrary extension boundaries. Metadata-free clauses, never line keys.
[
  %{
    file: "lib/crosswake/compatibility/route_gate.ex",
    module: "Crosswake.Compatibility.RouteGate",
    function: "check_dependencies/2",
    call: "companion.validate_dependency()",
    clause: """
    _extension_error ->
      result = {{:error, nil}, :adapter_unloadable}
      {result, %{companion_id: companion.companion_id(), route_id: route.id, exception: true}}
    """
  },
  %{
    file: "lib/crosswake/compatibility/route_gate.ex",
    module: "Crosswake.Compatibility.RouteGate",
    function: "prepend_auth_evaluation_denials/4",
    call: "authority.evaluate_auth(route, auth_context, opts)",
    clause: """
    _extension_error ->
      {:deny,
       Denial.new(
         reason: :dependency_missing,
         message:
           "[crosswake] companion \#{authority.companion_id()} raised during " <>
             "evaluate_auth/3. The gate fails closed.",
         route_id: route.id,
         details: %{"companion_id" => Atom.to_string(authority.companion_id())}
       )}
    """
  }
]
