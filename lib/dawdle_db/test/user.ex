defmodule DawdleDB.Test.User do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  schema "users" do
    field(:name, :string, null: false)
    field(:email, :string)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :email])
    |> validate_required(:name)
  end
end
