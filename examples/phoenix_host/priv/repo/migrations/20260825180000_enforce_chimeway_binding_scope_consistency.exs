defmodule CrosswakeExample.Repo.Migrations.EnforceChimewayBindingScopeConsistency do
  use Ecto.Migration

  @insert_guard "chimeway_token_bindings_subject_scope_consistency_insert_guard"
  @update_guard "chimeway_token_bindings_subject_scope_consistency_update_guard"

  def up do
    # An active row with contradictory authority facts must never remain eligible.
    # The existing terminal session-revoked vocabulary preserves lifecycle evidence
    # without inventing replacement authority.
    execute("""
    UPDATE chimeway_token_bindings
    SET state = 'revoked', reason = 'session_revoked', revoked_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE state = 'active'
      AND NOT (
        (subject_scope = 'subject_session'
          AND session_ref IS NOT NULL
          AND length(trim(session_ref)) > 0
          AND session_version IS NOT NULL
          AND session_version >= 0)
        OR
        (subject_scope = 'subject_installation'
          AND session_ref IS NULL
          AND session_version IS NULL)
      )
    """)

    create_scope_guard(@insert_guard, "INSERT")
    create_scope_guard(@update_guard, "UPDATE")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS #{@update_guard}")
    execute("DROP TRIGGER IF EXISTS #{@insert_guard}")

    # Reversing the guards intentionally does not resurrect rows reconciled in up/0.
  end

  defp create_scope_guard(name, operation) do
    execute("""
    CREATE TRIGGER #{name}
    BEFORE #{operation} ON chimeway_token_bindings
    FOR EACH ROW
    WHEN NEW.state = 'active'
      AND NOT (
        (NEW.subject_scope = 'subject_session'
          AND NEW.session_ref IS NOT NULL
          AND length(trim(NEW.session_ref)) > 0
          AND NEW.session_version IS NOT NULL
          AND NEW.session_version >= 0)
        OR
        (NEW.subject_scope = 'subject_installation'
          AND NEW.session_ref IS NULL
          AND NEW.session_version IS NULL)
      )
    BEGIN
      SELECT RAISE(ABORT, 'chimeway active binding subject scope must match session authority');
    END
    """)
  end
end
