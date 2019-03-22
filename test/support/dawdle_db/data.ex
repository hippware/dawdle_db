# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule DawdleDB.Data do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  schema "data" do
    field :pid, :string
    field :text, :string

    timestamps()
  end

  def changeset(struct, params) do
    cast(struct, params, [:pid, :text])
  end
end
