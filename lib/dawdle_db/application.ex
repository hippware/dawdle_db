defmodule DawdleDB.Application do
  @moduledoc false

  use Application

  alias DawdleDB.Watcher.Supervisor, as: WatcherSup
  alias DawdleDB.Watcher.SwarmContainer

  @impl true
  def start(_type, _args) do
    # List all child processes to be supervised
    children = []

    if Confex.get_env(:dawdle_db, :start_watcher) do
      repo = Confex.get_env(:dawdle_db, :ecto_repo)

      {:ok, _} =
        Swarm.whereis_or_register_name(
          DawdleDBWatcher,
          SwarmContainer,
          :start_link,
          [WatcherSup, :start_link, [repo]],
          5000
        )
    end

    opts = [strategy: :one_for_one, name: DawdleDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
