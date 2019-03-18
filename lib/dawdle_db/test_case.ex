defmodule DawdleDB.TestCase do
  @moduledoc """
  Module to set up the db watcher/callback system for test cases that require it
  """

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, async: false

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import unquote(__MODULE__)

      alias Ecto.Adapters.SQL.Sandbox, as: SQLSandbox
      alias unquote(opts[:repo])

      setup_all do
        Dawdle.Client.clear_all_handlers()
        SQLSandbox.mode(unquote(opts[:repo]), :auto)

        # Give any DB notifications still in the system from previous tests
        # a grace period to finish up before we start the watcher
        Process.sleep(500)

        DawdleDB.Watcher.Supervisor.start_link()

        :ok
      end
    end
  end
end
