defmodule DawdleDB.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: DawdleDB.Repo

  alias DawdleDB.Data
  alias Faker.Lorem

  def data_factory do
    %Data{
      text: Lorem.sentence()
    }
  end
end
