defmodule Aida.Recurrence.Monthly do
  alias __MODULE__
  require IEx

  defstruct start: nil,
            every: 1,
            each: 1

  defimpl Aida.Recurrence, for: __MODULE__ do
    def next(%Monthly{start: start, each: each, every: every}, now) do
      # Move the start to the next date on which `each` occurs
      start = start |> adjust_to_each(each, 1)

      if DateTime.compare(start, now) == :gt do
        # We're before the start date of the recurrence. Just return the start date.
        start
      else
        # Count the number of whole periods (`every` months) passed since the start date
        diff_in_periods = diff_in_months(start, now) |> div(every)

        start
        # Temporarily set the day to 1 to avoid issues while moving the day forward for shorter months
        |> Timex.set(day: 1)
        # Move to the next period
        |> Timex.shift(months: (diff_in_periods + 1) * every)
        # Set the day moving forard to the next month that have that day
        |> adjust_to_each(each, every)
      end
    end

    defp adjust_to_each(%{day: each} = start, each, _every), do: start

    defp adjust_to_each(%{day: day} = start, each, every) when day < each do
      if Timex.days_in_month(start) < each do
        start
        |> Timex.shift(months: every)
        |> adjust_to_each(each, every)
      else
        Timex.set(start, day: each)
      end
    end

    defp adjust_to_each(%{day: day, month: month} = start, each, _every) when day > each do
      Timex.set(start, day: each, month: month + 1)
    end

    # Calculate the number of whole months between two datetimes
    # A whole month is considered between to days with the same number, at the same time
    # This function assumes that `to` is greater than `from`
    defp diff_in_months(from, to) do
      months_diff = 12 * (to.year - from.year) + to.month - from.month
      from_time = from |> DateTime.to_time()
      to_time = to |> DateTime.to_time()

      cond do
        from.day > to.day ->
          months_diff - 1

        from.day == to.day && Time.compare(to_time, from_time) == :lt ->
          months_diff - 1

        :else ->
          months_diff
      end
    end
  end
end
