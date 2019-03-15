defmodule DawdleDB.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [DawdleDB.Client]

    children =
      if Mix.env() == :test do
        children ++ [DawdleDB.Test.Repo]
      else
        children
      end

    opts = [strategy: :one_for_one, name: DawdleDB.Supervisor]
    sup = Supervisor.start_link(children, opts)

    DawdleDB.Client.register()

    sup
  end
end
