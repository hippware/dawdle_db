defmodule DawdleDB.Repo.Migrations.AddEmbeddedData do
  use Ecto.Migration

  def change do
    alter table(:data) do
      add(:single_embed, :map, default: %{})
      add(:multi_embed, {:array, :map}, default: [])
    end
  end
end
