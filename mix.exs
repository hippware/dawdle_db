defmodule DawdleDB.MixProject do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :dawdle_db,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      package: package(),
      description: description(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        flags: [
          :error_handling,
          :race_conditions,
          :underspecs,
          :unknown,
          :unmatched_returns
        ],
        plt_add_apps: [:ex_unit],
        ignore_warnings: "dialyzer_ignore.exs",
        list_unused_filters: true
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
          port: {:system, :integer, "DAWDLEDB_DB_PORT", 5432},
          pool_size: {:system, :integer, "DAWDLEDB_DB_POOL_SIZE", 10}
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
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dawdle, "~> 0.5"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sqs, "~> 2.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:ex_machina, "~> 2.3", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:faker, "~> 0.12", only: :test},
      {:poison, "~> 3.0 or ~> 4.0"},
      {:postgrex, "~> 0.15.0"},
      {:telemetry, "~> 0.4.0"},
      {:timex, "~> 3.5"}
    ]
  end

  defp aliases do
    [
      ci: ["credo -a --strict --verbose", "ecto.migrate", "test"]
    ]
  end

  defp description do
    """
    DawdleDB uses Dawdle and SQS to capture change notifications from
    PostgreSQL.
    """
  end

  defp package do
    [
      maintainers: ["Bernard Duggan", "Phil Toland"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/hippware/dawdle_db"}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
