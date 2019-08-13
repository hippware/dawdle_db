defmodule DawdleDBCleanerTest do
  use ExUnit.Case, async: false

  import DawdleDB.TestHelper

  alias DawdleDB.Cleaner
  alias DawdleDB.Repo
  alias Faker.Lorem

  @insert_query "INSERT INTO watcher_events (payload, created_at) VALUES ($1, $2) RETURNING *"
  setup do
    start_watcher(Repo)
    Postgrex.query!(:watcher_postgrex, "DELETE FROM watcher_events", [])

    new =
      Postgrex.query!(:watcher_postgrex, @insert_query, [Lorem.word(), DateTime.utc_now()]).rows

    _old =
      Postgrex.query!(:watcher_postgrex, @insert_query, [
        Lorem.word(),
        Timex.shift(DateTime.utc_now(), hours: -2)
      ])

    {:ok, new: new}
  end

  test "cleans up old records", ctx do
    assert {:noreply, nil, _} = Cleaner.handle_info(:timeout, nil)

    assert Postgrex.query!(:watcher_postgrex, "SELECT * FROM watcher_events", []).rows ==
             ctx.new
  end
end
