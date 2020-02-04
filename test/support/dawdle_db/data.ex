# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule DawdleDB.Data do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  schema "data" do
    field :pid, :string
    field :text, :string
    field :map, :map

    embeds_one(:single_embed, DawdleDB.EmbedData)
    embeds_many(:multi_embed, DawdleDB.EmbedData)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:pid, :text])
    |> cast_embed(:single_embed)
    |> cast_embed(:multi_embed)
  end
end
