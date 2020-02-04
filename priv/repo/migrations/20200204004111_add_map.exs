defmodule DawdleDB.Repo.Migrations.AddMap do
  use Ecto.Migration

  def change do
    alter table(:data) do
      add :map, :map, default: %{}
    end
  end
end
