defmodule DawdleDB.Handler do
  @moduledoc """
  Helper module for DB callback modules
  """

  alias Ecto.Changeset
  alias Ecto.Schema

  @callback handle_insert(new :: Schema.t()) :: any()
  @callback handle_update(new :: Schema.t(), old :: Schema.t()) :: any()
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

      @impl Dawdle.Handler
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

      @impl DawdleDB.Handler
      def handle_insert(_new), do: :ok

      @impl DawdleDB.Handler
      def handle_update(_new, _old), do: :ok

      @impl DawdleDB.Handler
      def handle_delete(_old), do: :ok

      defoverridable handle_insert: 1, handle_update: 2, handle_delete: 1
    end
  end

  @doc false
  def _rehydrate(_type, nil), do: nil

  def _rehydrate(type, data) do
    type.__struct__
    |> Changeset.cast(data, type.__schema__(:fields))
    |> Changeset.apply_changes()
  end

  @doc false
  def _expand_alias({:__aliases__, _, _} = ast, env),
    do: Macro.expand(ast, %{env | function: {:__schema__, 2}})

  def _expand_alias(ast, _env),
    do: ast
end
