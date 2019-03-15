defmodule DawdleDB.Factory do
  use ExMachina.Ecto, repo: DawdleDB.Test.Repo

  alias DawdleDB.Test.User

  def user_factory do
    %User{
      name: "Jane Smith",
      email: sequence(:email, &"email-#{&1}@example.com")
    }
  end
end
