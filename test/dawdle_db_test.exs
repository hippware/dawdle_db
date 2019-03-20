defmodule DawdleDBTest do
  use ExUnit.Case, async: false

  import DawdleDB.TestHelper

  alias Faker.Lorem
  alias Dawdle.MessageEncoder.Term
  alias DawdleDB.Factory
  alias DawdleDB.Data
  alias DawdleDB.Repo

  defmodule TestHandler do
    use DawdleDB.Handler, type: DawdleDB.Data

    def handle_insert(%Data{pid: spid} = new) do
      pid = Term.decode(spid)
      send(pid, {:insert, new})
    end

    def handle_update(%Data{pid: spid} = new, old) do
      pid = Term.decode(spid)
      send(pid, {:update, new, old})
    end

    def handle_delete(%Data{pid: spid} = old) do
      pid = Term.decode(spid)
      send(pid, {:delete, old})
    end
  end

  setup_all do
    TestHandler.register()
    start_watcher(DawdleDB.Repo)

    :ok
  end

  test "generates insert event" do
    pid = self()

    %{id: id} = Factory.insert(:data, pid: Term.encode(pid))

    assert_receive {:insert, %Data{id: ^id}}, 500
  end

  test "generates update event" do
    pid = self()

    data = %{id: id} = Factory.insert(:data, pid: Term.encode(pid))

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
    pid = self()

    data = %{id: id} = Factory.insert(:data, pid: Term.encode(pid))

    Repo.delete(data)

    assert_receive {:delete, %Data{id: ^id}}, 500
  end
end
