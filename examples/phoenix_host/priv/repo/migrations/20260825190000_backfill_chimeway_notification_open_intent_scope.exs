defmodule CrosswakeExample.Repo.Migrations.BackfillChimewayNotificationOpenIntentScope do
  use Ecto.Migration

  def up do
    # A legacy intent may gain current authority only from its exact active binding.
    # All copied facts must already agree; this migration never supplies a default.
    execute("""
    UPDATE chimeway_notification_open_intents AS intent
    SET scope = (
      SELECT binding.subject_scope
      FROM chimeway_token_bindings AS binding
      WHERE binding.binding_ref = intent.binding_ref
        AND binding.state = 'active'
        AND binding.subject_scope IN ('subject_session', 'subject_installation')
        AND binding.org_ref = intent.tenant_ref
        AND binding.subject_ref = intent.subject_ref
        AND (
          (binding.subject_scope = 'subject_session'
            AND binding.session_ref IS NOT NULL
            AND length(trim(binding.session_ref)) > 0
            AND binding.session_version IS NOT NULL
            AND binding.session_version >= 0
            AND intent.session_ref = binding.session_ref
            AND intent.session_version = binding.session_version)
          OR
          (binding.subject_scope = 'subject_installation'
            AND binding.session_ref IS NULL
            AND binding.session_version IS NULL
            AND intent.session_ref IS NULL
            AND intent.session_version IS NULL)
        )
    )
    WHERE intent.state = 'issued'
      AND EXISTS (
        SELECT 1
        FROM chimeway_token_bindings AS binding
        WHERE binding.binding_ref = intent.binding_ref
          AND binding.state = 'active'
          AND binding.subject_scope IN ('subject_session', 'subject_installation')
          AND binding.org_ref = intent.tenant_ref
          AND binding.subject_ref = intent.subject_ref
          AND (
            (binding.subject_scope = 'subject_session'
              AND binding.session_ref IS NOT NULL
              AND length(trim(binding.session_ref)) > 0
              AND binding.session_version IS NOT NULL
              AND binding.session_version >= 0
              AND intent.session_ref = binding.session_ref
              AND intent.session_version = binding.session_version)
            OR
            (binding.subject_scope = 'subject_installation'
              AND binding.session_ref IS NULL
              AND binding.session_version IS NULL
              AND intent.session_ref IS NULL
              AND intent.session_version IS NULL)
          )
      )
    """)

    # Anything still issued cannot satisfy the current authorization contract.
    # Terminal revocation prevents a partial legacy row from remaining eligible.
    execute("""
    UPDATE chimeway_notification_open_intents AS intent
    SET state = 'revoked', updated_at = CURRENT_TIMESTAMP
    WHERE intent.state = 'issued'
      AND NOT EXISTS (
        SELECT 1
        FROM chimeway_token_bindings AS binding
        WHERE binding.binding_ref = intent.binding_ref
          AND binding.state = 'active'
          AND binding.subject_scope IN ('subject_session', 'subject_installation')
          AND intent.scope = binding.subject_scope
          AND binding.org_ref = intent.tenant_ref
          AND binding.subject_ref = intent.subject_ref
          AND (
            (binding.subject_scope = 'subject_session'
              AND binding.session_ref IS NOT NULL
              AND length(trim(binding.session_ref)) > 0
              AND binding.session_version IS NOT NULL
              AND binding.session_version >= 0
              AND intent.session_ref = binding.session_ref
              AND intent.session_version = binding.session_version)
            OR
            (binding.subject_scope = 'subject_installation'
              AND binding.session_ref IS NULL
              AND binding.session_version IS NULL
              AND intent.session_ref IS NULL
              AND intent.session_version IS NULL)
          )
      )
    """)
  end
end
