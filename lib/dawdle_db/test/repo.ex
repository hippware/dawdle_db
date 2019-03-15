defmodule DawdleDB.Test.Repo do
  use Ecto.Repo,
    otp_app: :dawdle_db,
    adapter: Ecto.Adapters.Postgres
end
