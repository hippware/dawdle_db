defmodule DawdleDB.Watcher.Supervisor do
  @moduledoc false

  use Supervisor

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(config \\ []) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    config =
      :dawdle_db
      |> Confex.get_env(:db, [])
      |> Keyword.merge(config)
      |> Keyword.take([
        :hostname,
        :database,
        :username,
        :password,
        :port,
        :pool_size
      ])
      |> Keyword.put(:auto_reconnect, true)

    # List all child processes to be supervised
    children = [
      {Postgrex, Keyword.put(config, :name, :watcher_postgrex)},
      %{
        id: Postgrex.Notifications,
        start:
          {Postgrex.Notifications, :start_link,
           [Keyword.put(config, :name, :watcher_notifications)]}
      },
      {DawdleDB.Watcher, []},
      {DawdleDB.Cleaner, []}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
