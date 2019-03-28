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

  @type action :: :insert | :update | :delete
  @type t :: %__MODULE__{
    table: binary(),
    action: action(),
    old: map(),
    new: map()
  }
end
