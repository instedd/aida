defmodule Aida.RecurrenceTest do
  alias Aida.Recurrence
  alias Aida.Recurrence.Daily
  use ExUnit.Case
  use Aida.TimeMachine

  describe "daily recurrence" do
    test "defaults to every 1 day" do
      start = DateTime.utc_now
      assert %Daily{start: start} == %Daily{start: start, every: 1}
    end

    test "with start in the future" do
      start = ~N[2040-01-01 18:00:00] |> utc
      assert %Daily{start: start} |> Recurrence.next == start
    end

    test "after the start and before the time" do
      start = ~N[2000-01-01 18:00:00] |> utc
      now = ~N[2018-01-05 10:00:00] |> utc
      next = ~N[2018-01-05 18:00:00] |> utc
      assert %Daily{start: start} |> Recurrence.next(now) == next
    end

    test "after the start and after the time" do
      start = ~N[2000-01-01 18:00:00] |> utc
      now = ~N[2018-01-05 19:00:00] |> utc
      next = ~N[2018-01-06 18:00:00] |> utc
      assert %Daily{start: start} |> Recurrence.next(now) == next
    end

    test "after the start every 3 days" do
      start = ~N[2018-01-01 18:00:00] |> utc
      now = ~N[2018-01-05 19:00:00] |> utc
      next = ~N[2018-01-07 18:00:00] |> utc
      assert %Daily{start: start, every: 3} |> Recurrence.next(now) == next
    end
  end

  defp utc(naive_ts) do
    naive_ts |> DateTime.from_naive!("Etc/UTC")
  end
end
