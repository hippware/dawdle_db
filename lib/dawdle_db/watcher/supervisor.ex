defmodule DawdleDB.Watcher.Supervisor do
  @moduledoc """
  The Wocky DB Watcher Service.
  """
  use Supervisor

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    config = Confex.fetch_env!(:dawdle_db, :db)

    # List all child processes to be supervised
    children = [
      {Postgrex, Keyword.put(config, :name, :watcher_postgrex)},
      %{
        id: Postgrex.Notifications,
        start:
          {Postgrex.Notifications, :start_link,
           [Keyword.put(config, :name, :watcher_notifications)]}
      },
      {DawdleDB.Watcher, []}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
