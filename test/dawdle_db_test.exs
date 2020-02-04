# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule DawdleDBTest do
  use ExUnit.Case, async: false

  import DawdleDB.TestHelper

  alias Dawdle.MessageEncoder.Term
  alias DawdleDB.Data
  alias DawdleDB.Factory
  alias DawdleDB.Repo
  alias Faker.Lorem

  defmodule TestHandler do
    use DawdleDB.Handler, type: DawdleDB.Data

    def handle_insert(%Data{pid: spid} = new) do
      {:ok, pid} = Term.decode(spid)
      send(pid, {:insert, new})
    end

    def handle_update(%Data{pid: spid} = new, old) do
      {:ok, pid} = Term.decode(spid)
      send(pid, {:update, new, old})
    end

    def handle_delete(%Data{pid: spid} = old) do
      {:ok, pid} = Term.decode(spid)
      send(pid, {:delete, old})
    end
  end

  setup_all do
    TestHandler.register()
    start_watcher(DawdleDB.Repo)

    :ok
  end

  test "generates insert event" do
    {:ok, spid} = Term.encode(self())

    %{id: id} = Factory.insert(:data, pid: spid)

    assert_receive {:insert, %Data{id: ^id}}, 500
  end

  test "generates update event" do
    {:ok, spid} = Term.encode(self())

    data = %{id: id} = Factory.insert(:data, pid: spid)

    data
    |> Data.changeset(%{text: Lorem.sentence()})
    |> Repo.update()

    assert_receive {
                     :update,
                     %Data{id: ^id, text: text},
                     %Data{id: ^id, text: text2}
                   }
                   when text != text2,
                   500
  end

  test "generates delete event" do
    {:ok, spid} = Term.encode(self())

    data = %{id: id} = Factory.insert(:data, pid: spid)

    Repo.delete(data)

    assert_receive {:delete, %Data{id: ^id}}, 500
  end

  test "correclty recovers map data" do
    {:ok, spid} = Term.encode(self())

    %{id: id, map: map} = Factory.insert(:data, pid: spid)

    assert_receive {:insert, %Data{id: ^id, map: ^map}}, 500
  end
end
