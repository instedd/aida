defmodule Aida.DelayedMessage do
  @type t :: %__MODULE__{
    delay: pos_integer,
    message: Aida.Bot.message
  }

  defstruct delay: 1,
            message: %{}

end
