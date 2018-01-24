defmodule Aida.Recurrence.Weekly do
  alias __MODULE__

  @type dow :: :sunday | :monday | :tuesday | :wednesday | :thursday | :friday | :saturday
  @type t :: %__MODULE__{
    start: DateTime.t,
    every: pos_integer,
    on: [dow]
  }

  defstruct start: nil,
            every: 1,
            on: []

  defimpl Aida.Recurrence, for: __MODULE__ do
    def next(%Weekly{}, now) do
      now
    end
  end
end
