defmodule DawdleDB.Event do
  @moduledoc """
  Struct containing an event from the DB watcher
  """

  defstruct [
    :table,
    :action,
    :old,
    :new
  ]

  @type t :: %__MODULE__{}
end
