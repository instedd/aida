defmodule Aida.Recurrence.Daily do
  alias __MODULE__

  @type t :: %__MODULE__{
    start: DateTime.t,
    every: pos_integer
  }

  defstruct start: nil,
            every: 1

  defimpl Aida.Recurrence, for: __MODULE__ do
    @seconds_in_a_day 86_400

    def next(%Daily{start: start, every: every}, now) do
      if DateTime.compare(start, now) == :gt do
        start
      else
        diff_in_periods = DateTime.diff(now, start) |> div(@seconds_in_a_day * every)
        Timex.shift(start, days: (diff_in_periods + 1) * every)
      end
    end
  end
end
