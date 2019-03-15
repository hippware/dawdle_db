defmodule DawdleDB.Client do
  @moduledoc """
  The client for the DawdleDB - entities interested in queue events
  should subscribe to this process.
  """

  defmodule State do
    @moduledoc false
    defstruct [:subscribers, :table_map]
  end

  use Dawdle.Handler, only: [DawdleDB.Event]
  use GenServer

  alias DawdleDB.Event
  alias Ecto.Changeset

  require Logger

  @doc false
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Dawdle.Handler
  def handle_event(event) do
    GenServer.cast(__MODULE__, {:handle_event, event})
  end

  def subscribe(object, action, fun) do
    GenServer.call(__MODULE__, {:subscribe, object, action, fun})
  end

  def unsubscribe(ref) do
    GenServer.call(__MODULE__, {:unsubscribe, ref})
  end

  def clear_all_subscriptions do
    GenServer.call(__MODULE__, :clear_all_subscriptions)
  end

  @impl GenServer
  def init(_) do
    {:ok, %State{subscribers: %{}, table_map: Map.new()}}
  end

  @impl GenServer
  def handle_cast({:handle_event, event}, state) do
    {object, event} = fixup_event(event, state.table_map)

    state.subscribers
    |> Map.get({object, event.action}, [])
    |> Enum.each(&call_handler(&1, event))

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:subscribe, object, action, fun}, _from, state) do
    current = Map.get(state.subscribers, {object, action}, MapSet.new())
    ref = make_ref()

    new_subscribers =
      Map.put(
        state.subscribers,
        {object, action},
        MapSet.put(current, {fun, ref})
      )

    new_table_map = Map.put(state.table_map, object.__schema__(:source), object)

    {:reply, {:ok, ref}, %{state | subscribers: new_subscribers, table_map: new_table_map}}
  end

  def handle_call({:unsubscribe, ref}, _from, state) do
    new_subscribers =
      state.subscribers
      |> Enum.map(&delete_ref(&1, ref))
      |> Map.new()

    {:reply, :ok, %{state | subscribers: new_subscribers}}
  end

  def handle_call(:clear_all_subscriptions, _from, state) do
    {:reply, :ok, %{state | subscribers: %{}}}
  end

  @impl GenServer
  def handle_info(_, state), do: {:noreply, state}

  defp fixup_event(
         %Event{table: table, old: old, new: new} = event,
         table_map
       ) do
    case Map.get(table_map, table) do
      nil ->
        {nil, event}

      object ->
        {object,
         %{
           event
           | old: convert_object(object, old),
             new: convert_object(object, new)
         }}
    end
  end

  defp convert_object(_object, nil), do: nil

  defp convert_object(object, json) do
    object.__struct__
    |> Changeset.cast(json, object.__schema__(:fields))
    |> Changeset.apply_changes()
  end

  defp call_handler({fun, _ref}, event) do
    fun.(event)
  rescue
    error ->
      Logger.error("""
      DawdleDB event handler crash:
      Event: #{inspect(event, pretty: true)}
      Error: #{inspect(error, pretty: true)}

      #{inspect(__STACKTRACE__, pretty: true)}
      """)
  end

  defp delete_ref({key, val}, ref) do
    to_delete = Enum.find(val, fn v -> elem(v, 1) == ref end)
    {key, MapSet.delete(val, to_delete)}
  end
end
