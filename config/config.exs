use Mix.Config

if Mix.env() == :test do
  config :dawdle, start_pollers: true

  config :dawdle_db, ecto_repos: [DawdleDB.Repo],

  config :dawdle_db, DawdleDB.Repo,
    database: {:system, "DAWDLEDB_DB_DATABASE", "dawdle_db_test"},
    username: {:system, "DAWDLEDB_DB_USERNAME", "postgres"},
    password: {:system, "DAWDLEDB_DB_PASSWORD", "password"},
    hostname: {:system, "DAWDLEDB_DB_HOSTNAME", "localhost"},
    show_sensitive_data_on_connection_error: true,
    pool: Ecto.Adapters.SQL.Sandbox

  config :logger, level: :info
end
