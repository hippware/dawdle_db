defmodule DawdleDB.TestHelper do
  @moduledoc """
  Module to set up the db watcher/callback system for test cases that require it
  """

  import ExUnit.Callbacks, only: [start_supervised!: 1]

  alias Ecto.Adapters.SQL.Sandbox, as: SQLSandbox

  @spec start_watcher(Ecto.Repo.t()) :: pid()
  def start_watcher(repo) do
    SQLSandbox.mode(repo, :auto)

    start_supervised!({DawdleDB.Watcher.Supervisor, repo.config})
  end
end
