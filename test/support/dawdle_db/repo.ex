defmodule DawdleDB.Repo do
  use Ecto.Repo,
    otp_app: :dawdle_db,
    adapter: Ecto.Adapters.Postgres

  alias Confex.Resolver

  @impl true
  def init(_, opts) do
    {:ok, Resolver.resolve!(opts)}
  end
end
