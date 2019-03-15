defmodule DawdleDBTest do
  use DawdleDB.TestCase, repo: DawdleDB.Test.Repo

  alias Faker.Lorem
  alias DawdleDB.Client
  alias DawdleDB.Event
  alias DawdleDB.Factory
  alias DawdleDB.Test.User

  setup do
    Client.clear_all_subscriptions()
  end

  test "generates insert event" do
    pid = self()

    Client.subscribe(User, :insert, fn event -> send(pid, event) end)

    %{id: uid} = Factory.insert(:user)

    assert_receive %Event{action: :insert, old: nil, new: %User{id: ^uid}}, 500
  end

  test "generates update event" do
    pid = self()

    Client.subscribe(User, :update, fn event -> send(pid, event) end)

    user = %{id: uid} = Factory.insert(:user)

    user
    |> cast(%{name: Lorem.sentence()}, [:name])
    |> Repo.update()

    assert_receive %Event{
                     action: :update,
                     old: %User{id: ^uid, name: name},
                     new: %User{id: ^uid, name: name2}
                   }
                   when name != name2,
                   500
  end

  test "generates delete event" do
    pid = self()

    Client.subscribe(User, :delete, fn event -> send(pid, event) end)

    user = %{id: uid} = Factory.insert(:user)
    Repo.delete(user)

    assert_receive %Event{action: :delete, new: nil, old: %User{id: ^uid}}, 500
  end

  test "unsubscribe" do
    pid = self()

    {:ok, ref} =
      Client.subscribe(User, :insert, fn event -> send(pid, event) end)

    Client.unsubscribe(ref)

    Factory.insert(:user)

    refute_receive _, 200
  end

  test "crash handler" do
    client = Process.whereis(Client)
    {:ok, _ref} = Client.subscribe(User, :insert, &crash(&1))

    Factory.insert(:user)

    Process.sleep(500)
    client2 = Process.whereis(Client)
    assert client == client2
    assert Process.alive?(client)
  end

  defp crash(_event) do
    :lists.last([])
  end
end
