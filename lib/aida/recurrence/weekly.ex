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
    @seconds_in_a_day 86_400
    @seconds_in_a_week 604_800

    def next(%Weekly{start: start, on: on, every: every}, now) do
      if DateTime.compare(start, now) == :gt do
        # We're before the start date of the recurrence
        # Just adjust forward the date to one of the allowed days of week
        start
        |> adjust_day_of_week(on)
      else
        # Calculate the number of whole days between the start date and now
        diff_in_days = DateTime.diff(now, start) |> div(@seconds_in_a_day)

        start
        # This will select the current date at the start time if the current time
        # is before the start time, or the next day at start time otherwise
        |> Timex.shift(days: diff_in_days + 1)
        # Choose the next available day of week
        |> adjust_day_of_week(on)
        # Finally, move to the next enabled week (if `every` is greater than 1)
        |> adjust_every(start, every)
      end
    end

    # Move the datetime to the next enabled week. Does nothing if `every = 1`.
    # Note that actually the special case for `every = 1` is not necessary but
    # added just to avoid calculations.
    defp adjust_every(datetime, _, 1), do: datetime
    defp adjust_every(datetime, start, every) do
      # Calculate the number of whole weeks between the start date and the given date
      diff_in_weeks = DateTime.diff(datetime, start) |> div(@seconds_in_a_week)

      # Make the number of whole weeks a multiple of the `every` value
      case rem(diff_in_weeks, every) do
        0 ->
          # Already a multiple, no changes
          datetime
        rem ->
          Timex.shift(datetime, weeks: every - rem)
      end
    end

    # Moves forward the date to make it fall into one of the available days of week
    defp adjust_day_of_week(datetime, on) do
      # Get the selected day of week as an integer (1 - Monday, ..., 7 - Sunday)
      dow =
        datetime
        |> DateTime.to_date
        |> Date.day_of_week

      # Calculate the necessary offset and move forward the date
      offset = adjust_offset(dow, on)
      Timex.shift(datetime, days: offset)
    end

    # Calculate the offset in days between a day of week and the next available one
    # It works by moving to the next day of week until it succeeds (worst case: 6 iterations)
    defp adjust_offset(dow, on, offset \\ 0)
    defp adjust_offset(_, on, offset) when offset >= 7, do: raise "Invalid 'on' value for weekly recurrence: #{inspect on}"
    defp adjust_offset(dow, on, offset) do
      if dow_to_atom(dow) in on do
        offset
      else
        adjust_offset(next_dow(dow), on, offset + 1)
      end
    end

    defp dow_to_atom(1), do: :monday
    defp dow_to_atom(2), do: :tuesday
    defp dow_to_atom(3), do: :wednesday
    defp dow_to_atom(4), do: :thursday
    defp dow_to_atom(5), do: :friday
    defp dow_to_atom(6), do: :saturday
    defp dow_to_atom(7), do: :sunday

    defp next_dow(7), do: 1
    defp next_dow(dow), do: dow + 1
  end
end
