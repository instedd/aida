defmodule Aida.DelayedMessage do
  @type t :: %__MODULE__{
    delay: String.t(),
    message: Aida.Bot.message
  }

  defstruct delay: "",
            message: %{}

end
