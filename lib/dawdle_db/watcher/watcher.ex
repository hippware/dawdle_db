defmodule DawdleDB.Watcher do
  @moduledoc false

  defmodule State do
    @moduledoc false

    defstruct [
      :ref,
      :channel,
      :pending,
      :batch_timeout,
      :batch_max_size
    ]
  end

  use GenServer

  require Logger

  alias DawdleDB.Event
  alias Postgrex.Notifications

  @doc false
  @spec start_link(any()) :: GenServer.on_start()
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_) do
    channel = Confex.fetch_env!(:dawdle_db, :channel)
    batch_timeout = Confex.fetch_env!(:dawdle_db, :batch_timeout)
    batch_max_size = Confex.fetch_env!(:dawdle_db, :batch_max_size)

    ref = Notifications.listen!(:watcher_notifications, channel)

    {:ok,
     %State{
       ref: ref,
       channel: channel,
       pending: [],
       batch_timeout: batch_timeout,
       batch_max_size: batch_max_size
     }}
  end

  @impl true
  def handle_info(
        {:notification, _, ref, channel, payload},
        %State{ref: ref, channel: channel} = state
      ) do
    start_time = System.monotonic_time()
    :telemetry.execute(
      [:dawdle_db, :notification, :start],
      %{time: start_time},
      %{}
    )

    j = parse(payload)

    result =
      Postgrex.query!(
        :watcher_postgrex,
        "DELETE FROM watcher_events WHERE id = $1 RETURNING payload",
        [j.id]
      )

    result =
      if result.num_rows == 1 do
        full_event = parse(hd(result.rows))

        %Event{
          table: full_event.table,
          action: String.to_existing_atom(full_event.action)
        }
        |> maybe_add_rec(:old, full_event)
        |> maybe_add_rec(:new, full_event)
        |> send_or_enqueue(state)
      else
        {:noreply, state}
      end

    duration = System.monotonic_time() - start_time
    :telemetry.execute(
      [:dawdle_db, :notification, :stop],
      %{duration: duration},
      %{}
    )

    result
  end

  def handle_info(:timeout, state), do: flush(state)

  def handle_info(_info, state), do: {:noreply, state}

  defp maybe_add_rec(event, field, map) do
    case Map.get(map, field) do
      nil -> event
      rec -> Map.put(event, field, rec)
    end
  end

  defp send_or_enqueue(
         msg,
         %{pending: pending, batch_max_size: max_batch} = state
       )
       when length(pending) == max_batch - 1 do
    flush(%{state | pending: [msg | pending]})
  end

  defp send_or_enqueue(
         msg,
         %{pending: pending, batch_timeout: batch_timeout} = state
       ) do

    :telemetry.execute(
      [:dawdle_db, :watcher, :enqueue],
      %{count: length(pending) + 1},
      %{}
    )

    {:noreply, %{state | pending: [msg | pending]}, batch_timeout}
  end

  defp flush(%State{pending: pending} = state) do
    :ok =
      pending
      |> Enum.reverse()
      |> Dawdle.signal()

    :telemetry.execute(
      [:dawdle_db, :watcher, :flush],
      %{count: length(pending)},
      %{}
    )

    {:noreply, %{state | pending: []}}
  end

  # Ideally we'd use 'atoms!' here, but we don't actually know all the object keys
  defp parse(payload) do
    start_time = System.monotonic_time()
    :telemetry.execute(
      [:dawdle_db, :parse, :start],
      %{time: start_time},
      %{}
    )

    result = Poison.decode!(payload, keys: :atoms)

    duration = System.monotonic_time() - start_time
    :telemetry.execute(
      [:dawdle_db, :parse, :stop],
      %{duration: duration},
      %{}
    )

    result
  end
end
