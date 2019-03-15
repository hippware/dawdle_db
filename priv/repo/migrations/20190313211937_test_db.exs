defmodule DawdleDB.Repo.Migrations.TestDb do
  use Ecto.Migration

  import DawdleDB.Migration

  def up do
    create_watcher_events_table()

    create table(:users) do
      add :name, :string, null: false
      add :email, :string

      timestamps()
    end

    update_notify("users", [:insert, :update, :delete])
  end

  def down do
    drop table("watcher_events")
    drop table(:users)
  end
end
