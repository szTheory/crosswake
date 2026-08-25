defmodule CrosswakeExample.Repo.Migrations.ProtectChimewayNotificationOpenIntentHistory do
  use Ecto.Migration

  @history_guard "chimeway_notification_open_intents_event_history_delete_guard"

  def up do
    execute("""
    CREATE TRIGGER #{@history_guard}
    BEFORE DELETE ON chimeway_notification_open_intents
    FOR EACH ROW
    WHEN EXISTS (
      SELECT 1
      FROM chimeway_notification_open_intent_events
      WHERE open_intent_id = OLD.id
    )
    BEGIN
      SELECT RAISE(ABORT, 'notification-open intent history is retained');
    END
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS #{@history_guard}")
  end
end
