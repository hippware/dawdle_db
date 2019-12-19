# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule DawdleDB.EmbedData do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:key, :string, []}

  schema "data" do
    field :value, :string

    embeds_one(:inception, DawdleDB.EmbedData)
  end

  def changeset(struct, params) do
    cast(struct, params, [:key, :value])
    |> cast_embed(:inception)
  end
end
