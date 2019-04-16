defmodule DawdleDB.Event do
  @moduledoc false

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
