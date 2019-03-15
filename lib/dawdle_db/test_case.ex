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
      import DawdleDB.Eventually

      alias Ecto.Adapters.SQL.Sandbox, as: SQLSandbox
      alias unquote(opts[:repo])

      setup_all do
        DawdleDB.Client.clear_all_subscriptions()
        SQLSandbox.mode(unquote(opts[:repo]), :auto)

        # Give any DB notifications still in the system from previous tests
        # a grace period to finish up before we start the watcher
        Process.sleep(500)

        DawdleDB.Watcher.Supervisor.start_link()

        # Because we can't use the Sandbox in its :manual mode (because it doesn't
        # cause the NOTIFY actions in the DB to fire) we have to do our own cleanup
        on_exit(fn ->
          cleanup()
        end)
      end

      def cleanup do
        :ok
      end

      defoverridable cleanup: 0
    end
  end
end
