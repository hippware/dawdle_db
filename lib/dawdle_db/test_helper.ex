defmodule DawdleDB.TestHelper do
  @moduledoc """
  Helpers for writing tests that exercise the DawdleDB system.
  """

  import ExUnit.Callbacks, only: [start_supervised!: 1]

  alias Ecto.Adapters.SQL.Sandbox, as: SQLSandbox

  @doc """
  Set up the DB watcher/callback system for test cases that require it.
  """
  @spec start_watcher(Ecto.Repo.t()) :: pid()
  def start_watcher(repo) do
    SQLSandbox.mode(repo, :auto)

    start_supervised!({DawdleDB.Watcher.Supervisor, repo.config})
  end
end
