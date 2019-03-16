defmodule DawdleDB.MixProject do
  use Mix.Project

  def project do
    [
      app: :dawdle_db,
      version: "0.5.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      env: [
        channel: {:system, "DAWDLEDB_CHANNEL", "dawdle_db_watcher_notify"},
        batch_timeout: 50,
        batch_max_size: 10,
        db: [
          database: {:system, "DAWDLEDB_DB_DATABASE", ""},
          username: {:system, "DAWDLEDB_DB_USERNAME", "postgres"},
          password: {:system, "DAWDLEDB_DB_PASSWORD", "password"},
          hostname: {:system, "DAWDLEDB_DB_HOSTNAME", "localhost"},
          port: {:system, :integer, "DAWDLEDB_DB_PORT", 5432}
        ]
      ]
    ]
  end

  # This makes sure your factory and any other modules in test/support are
  # compiled when in the test environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:confex, "~> 3.4"},
      {:dawdle, github: "hippware/dawdle", branch: "dev-0.5.0"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sqs, "~> 2.0"},
      {:poison, "~> 3.0 or ~> 4.0"},
      {:postgrex, "~> 0.14.0"},
      {:timex, "~> 3.5"},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_machina, "~> 2.3", only: :test},
      {:faker, "~> 0.12", only: :test}
    ]
  end
end
