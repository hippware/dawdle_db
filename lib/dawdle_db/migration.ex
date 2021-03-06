defmodule DawdleDB.Migration do
  @moduledoc """
  Utilities for managing the DawdleDB events table and notification related
  triggers.

  ## Examples

  ```
  defmodule MyApp.DawdleDBSetup do
    use Ecto.Migration

    import DawdleDB.Migration

    def up do
      create_watcher_events_table()
      update_notify("users", [:insert, :update, :delete])
    end

    def down do
      remove_notify("users", [:insert, :update, :delete])
      drop_watcher_events_table()
    end
  end
  ```
  """

  import Ecto.Migration

  alias DawdleDB.Event

  @type table :: binary
  @type override :: {binary, binary}

  @doc """
  Creates the DawdleDB watcher events table.

  This table is necessary for DawdleDB to manage events.
  """
  @spec create_watcher_events_table :: :ok
  def create_watcher_events_table do
    create table("watcher_events") do
      add :payload, :text, null: false

      timestamps(inserted_at: :created_at, updated_at: false)
    end

    :ok
  end

  @doc """
  Drops the DawdleDB watcher events table.
  """
  @spec drop_watcher_events_table :: :ok
  def drop_watcher_events_table do
    drop table("watcher_events")

    :ok
  end

  @doc """
  Add event notification function/trigger to a table.

  To override the encoding of particular fields, provide an override with
  `$ITEM$` as the item to be overridden. For example, to override the encoding
  of the "title" field, use: `{"title", "my_encoding_function($ITEM$)"}`.

  ## Examples

  ```
  update_notify("my_table", [:insert, :update])

  update_notify("other_table", [:insert], [{"title", "my_encoding_function($ITEM$)"}])
  ```
  """
  @spec update_notify(table(), [Event.action()], [override()]) :: :ok
  def update_notify(table, actions, overrides \\ [])

  def update_notify(table, actions, overrides) when is_list(actions) do
    Enum.each(actions, &update_notify(table, &1, overrides))
  end

  def update_notify(table, action_atom, overrides) do
    action = Atom.to_string(action_atom)

    execute("""
    CREATE OR REPLACE FUNCTION notify_#{table}_#{action}()
    RETURNS trigger AS $$
    DECLARE
      event_id bigint;
    BEGIN
      INSERT INTO watcher_events (payload, created_at) VALUES (
        json_build_object(
          'table', TG_TABLE_NAME
          ,'action', '#{action}'
          #{maybe_old(action, ",'old', #{wrap_overrides("OLD", overrides)}")}
          #{maybe_new(action, ",'new', #{wrap_overrides("NEW", overrides)}")}
        )::text,
        now()
      )
      RETURNING id INTO event_id;
      PERFORM pg_notify(
        '#{channel()}',
        json_build_object(
          'table', TG_TABLE_NAME,
          'action', '#{action}',
          'id', event_id
        )::text
      );
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("DROP TRIGGER IF EXISTS #{name(table, action)} ON #{table}")
    add_notify_trigger(table, action)

    :ok
  end

  defp channel do
    ensure_loaded(:dawdle_db)
    Confex.fetch_env!(:dawdle_db, :channel)
  end

  defp ensure_loaded(app) do
    case Application.load(app) do
      :ok -> :ok
      {:error, {:already_loaded, _}} -> :ok
    end
  end

  defp wrap_overrides(object, overrides) do
    wrap_overrides("to_jsonb(#{object})", object, overrides)
  end

  defp wrap_overrides(base, _object, []), do: base

  defp wrap_overrides(base, object, [{field, action} | rest]) do
    mapped_action =
      String.replace(action, "$ITEM$", "#{object}.#{field}", global: true)

    # We have to call COALESCE here because jsonb_set is, inexplicably, STRICT.
    # See
    # https://www.postgresql.org/message-id/flat/
    # 37E2F9B3-B65B-4AF2-B2E9-436ADE37D670%40gida.in#
    # 37E2F9B3-B65B-4AF2-B2E9-436ADE37D670@gida.in
    new = """
    jsonb_set(#{base}, '{#{field}}',
              COALESCE(to_jsonb(#{mapped_action}), 'null'))
    """

    wrap_overrides(new, object, rest)
  end

  defp maybe_old("insert", _), do: ""
  defp maybe_old(_, str), do: str

  defp maybe_new("delete", _), do: ""
  defp maybe_new(_, str), do: str

  # NOTE: Triggers are hard-coded here to fire AFTER the triggering transaction
  # is comitted. We don't ever want to fire them BEFORE because that delays
  # the transaction being comitted until the function returns, which introduces
  # a pointless delay. Why is it pointless? Because the function will put the
  # message into the SQS queue, and then complete the transaction. By the time
  # the message is processed by the app, the transaction has still finished,
  # gaining us nothing.
  defp add_notify_trigger(table, action) do
    execute("""
    CREATE TRIGGER #{name(table, action)}
    AFTER #{String.upcase(action)}
    ON #{table}
    FOR EACH ROW
    EXECUTE PROCEDURE #{name(table, action)}();
    """)
  end

  @doc """
  Remove event notification function/trigger from a table.

  ## Examples

  ```
  remove_notify("my_table", [:insert])
  ```
  """
  @spec remove_notify(table(), Event.action() | [Event.action()]) :: :ok
  def remove_notify(table, actions) when is_list(actions),
    do: Enum.each(actions, &remove_notify(table, &1))

  def remove_notify(table, action_atom) do
    action = Atom.to_string(action_atom)
    execute("DROP TRIGGER IF EXISTS #{name(table, action)} ON #{table}")
    execute("DROP FUNCTION IF EXISTS #{name(table, action)}()")

    :ok
  end

  defp name(table, action), do: "notify_#{table}_#{action}"
end
