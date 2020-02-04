defmodule DawdleDB.Cleaner do
  @moduledoc """
  Regularly cleans out the events table and logs any stale entries that
  were not processed.
  """

  use GenServer

  @clean_interval :timer.hours(1)
  @clean_older_than [hours: -1]

  require Logger

  @doc false
  @spec start_link(any()) :: GenServer.on_start()
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, nil, 0}
  end

  @impl true
  def handle_info(:timeout, state) do
    timestamp = Timex.shift(DateTime.utc_now(), @clean_older_than)

    result =
      Postgrex.query!(
        :watcher_postgrex,
        "DELETE FROM watcher_events WHERE created_at < $1 RETURNING *",
        [timestamp]
      )

    _ =
      case result.num_rows do
        0 ->
          :ok

        _ ->
          if Confex.get_env(:dawdle_db, :log_cleanup_errors) do
            log_cleanup_errors(result)
          end
      end

    {:noreply, state, @clean_interval}
  end

  def handle_info(_info, state), do: {:noreply, state}

  defp log_cleanup_errors(result) do
    Logger.error(
      "Cleaned #{result.num_rows} from watcher events table: #{
        inspect(result.rows)
      }"
    )
  end
end
