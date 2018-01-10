defmodule Aida.FixedTimeMessage do
  @type t :: %__MODULE__{
    schedule: DateTime.t,
    message: Aida.Bot.message
  }

  defstruct schedule: DateTime.utc_now,
            message: %{}
end
