defmodule DawdleDB.Repo.Migrations.TestDb do
  use Ecto.Migration

  import DawdleDB.Migration

  def up do
    create_watcher_events_table()

    create table(:data) do
      add :pid, :string
      add :text, :text

      timestamps()
    end

    update_notify("data", [:insert, :update, :delete])
  end

  def down do
    drop table(:data)
    drop_watcher_events_table()
  end
end
