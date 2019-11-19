defmodule DawdleDB do
  @moduledoc """
  Main module for DawdleDB.
  """

  alias DawdleDB.Watcher.Supervisor, as: WatcherSup

  @doc """
  Starts the DawdleDB notification watcher.

  Takes an `Ecto.Repo` and the configuration of that repo will be used to
  connect to the database.
  """
  @spec start_watcher(Ecto.Repo.t()) :: :ok | {:error, any()}
  def start_watcher(repo) do
    result = Loner.start(WatcherSup, repo.config)

    case result do
      {:ok, _} -> :ok
      {:error, _} = error -> error
    end
  end
end
