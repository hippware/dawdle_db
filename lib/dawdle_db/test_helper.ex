defmodule DawdleDB.TestHelper do
  @moduledoc """
  Module to set up the db watcher/callback system for test cases that require it
  """

  import ExUnit.Callbacks

  def start_watcher(repo) do
    Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)

    start_supervised!({DawdleDB.Watcher.Supervisor, repo.config})
  end
end
