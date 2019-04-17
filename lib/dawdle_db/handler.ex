defmodule DawdleDB.Handler do
  @moduledoc """
  Defines a handler for database events on a single table.

  To define an event handler, `use DawdleDB.Handler` and provide a Ecto schema
  type that you wish to handle. Then, override the callbacks
  `c:handle_insert/1`, `c:handle_update/2`, `c:handle_delete/1`,
  as appropriate.

  ## Examples

  ```
  defmodule MyApp.TestDBHandler do
    use DawdleDB.Handler, type: [MyApp.MySchema]

    alias MyApp.MySchema

    def handle_insert(%MySchema{} = new) do
      # Do something...
    end

    def handle_update(%MySchema{} = new, old) do
      # Do something else...
    end

    def handle_delete(%MySchema{} = old) do
      # Default case
    end
  end
  ```
  """

  alias Ecto.Changeset
  alias Ecto.Schema

  @doc """
  This function is called when DawdleDB pulls an insert event for the specified
  table from the queue. The function is executed for its side effects
  and the return value is ignored.
  """
  @callback handle_insert(new :: Schema.t()) :: any()

  @doc """
  This function is called when DawdleDB pulls an update event for the specified
  table from the queue. The function is executed for its side effects and the
  return value is ignored.
  """
  @callback handle_update(new :: Schema.t(), old :: Schema.t()) :: any()

  @doc """
  This function is called when DawdleDB pulls a delete event for the specified
  table from the queue. The function is executed for its side effects and the
  return value is ignored.
  """
  @callback handle_delete(old :: Schema.t()) :: any()

  defmacro __using__(opts) do
    type =
      opts
      |> Keyword.get(:type)
      |> DawdleDB.Handler._expand_alias(__CALLER__)

    table = type.__schema__(:source)

    quote do
      use Dawdle.Handler, only: [DawdleDB.Event]

      import DawdleDB.Handler, only: [_rehydrate: 2]

      @behaviour DawdleDB.Handler

      @impl true
      def handle_event(%DawdleDB.Event{table: unquote(table)} = e) do
        case e.action do
          :insert ->
            handle_insert(_rehydrate(unquote(type), e.new))

          :update ->
            handle_update(
              _rehydrate(unquote(type), e.new),
              _rehydrate(unquote(type), e.old)
            )

          :delete ->
            handle_delete(_rehydrate(unquote(type), e.old))
        end
      end

      # Catch-all handler
      def handle_event(_event), do: :ok

      @impl true
      def handle_insert(_new), do: :ok

      @impl true
      def handle_update(_new, _old), do: :ok

      @impl true
      def handle_delete(_old), do: :ok

      defoverridable handle_insert: 1, handle_update: 2, handle_delete: 1
    end
  end

  @doc false
  # credo:disable-for-lines:5 Credo.Check.Readability.Specs
  def _rehydrate(_type, nil), do: nil

  def _rehydrate(type, data) do
    type.__struct__
    |> Changeset.cast(data, type.__schema__(:fields))
    |> Changeset.apply_changes()
  end

  @doc false
  # credo:disable-for-lines:5 Credo.Check.Readability.Specs
  def _expand_alias({:__aliases__, _, _} = ast, env),
    do: Macro.expand(ast, %{env | function: {:__schema__, 2}})

  def _expand_alias(ast, _env),
    do: ast
end
