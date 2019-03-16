defmodule DawdleDB.Factory do
  use ExMachina.Ecto, repo: DawdleDB.Repo

  alias DawdleDB.Data
  alias Faker.Lorem

  def data_factory do
    %Data{
      text: Lorem.sentence()
    }
  end
end
