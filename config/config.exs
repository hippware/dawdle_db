use Mix.Config

if Mix.env() == :test do
  config :dawdle, start_pollers: true

  config :dawdle_db, ecto_repos: [DawdleDB.Repo]

  config :dawdle_db, DawdleDB.Repo,
    database: "dawdle_db_test",
    username: "postgres",
    password: "password",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox

  config :logger, level: :info
end
