use Mix.Config

config :dawdle_db, ecto_repos: [DawdleDB.Test.Repo]

config :dawdle_db, DawdleDB.Test.Repo,
  database: "dawdle_db_test",
  username: "postgres",
  password: "password",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :dawdle_db, :db,
  database: "dawdle_db_test"
