defmodule Aida.RecurrenceTest do
  alias Aida.Recurrence
  alias Aida.Recurrence.{Daily, Weekly}
  use ExUnit.Case
  use Aida.TimeMachine

  describe "daily recurrence" do
    test "defaults to every 1 day" do
      start = DateTime.utc_now
      assert %Daily{start: start} == %Daily{start: start, every: 1}
    end

    test "with start in the future" do
      start = ~U[2040-01-01 18:00:00]
      now = ~U[2018-01-01 10:00:00]
      assert %Daily{start: start} |> Recurrence.next(now) == start
    end

    test "after the start and before the time" do
      start = ~U[2000-01-01 18:00:00]
      now = ~U[2018-01-05 10:00:00]
      next = ~U[2018-01-05 18:00:00]
      assert %Daily{start: start} |> Recurrence.next(now) == next
    end

    test "after the start and after the time" do
      start = ~U[2000-01-01 18:00:00]
      now = ~U[2018-01-05 19:00:00]
      next = ~U[2018-01-06 18:00:00]
      assert %Daily{start: start} |> Recurrence.next(now) == next
    end

    test "after the start every 3 days" do
      start = ~U[2018-01-01 18:00:00]
      now = ~U[2018-01-05 19:00:00]
      next = ~U[2018-01-07 18:00:00]
      assert %Daily{start: start, every: 3} |> Recurrence.next(now) == next
    end
  end

  describe "weekly recurrence" do
    test "defaults to every 1 week" do
      start = DateTime.utc_now
      assert %Weekly{start: start, on: [:monday]} == %Weekly{start: start, on: [:monday], every: 1}
    end

    test "every week on a single day" do
      recurrence = %Weekly{start: ~U[2018-01-02 18:00:00], on: [:wednesday]}
      assert Recurrence.next(recurrence, ~U[2000-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 17:59:59]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 18:00:00]) == ~U[2018-01-10 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 18:10:00]) == ~U[2018-01-10 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-08 00:00:00]) == ~U[2018-01-10 18:00:00]
      assert Recurrence.next(recurrence, ~U[2818-01-01 00:00:00]) == ~U[2818-01-03 18:00:00]
    end

    test "every week, twice a week" do
      recurrence = %Weekly{start: ~U[2018-01-02 18:00:00], on: [:wednesday, :friday]}
      assert Recurrence.next(recurrence, ~U[2000-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 17:59:59]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 18:00:00]) == ~U[2018-01-05 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-04 18:00:00]) == ~U[2018-01-05 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-05 18:00:00]) == ~U[2018-01-10 18:00:00]
    end

    test "every other week on a single day" do
      recurrence = %Weekly{start: ~U[2018-01-02 18:00:00], on: [:wednesday], every: 2}
      assert Recurrence.next(recurrence, ~U[2000-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 17:59:59]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 18:00:00]) == ~U[2018-01-17 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 18:10:00]) == ~U[2018-01-17 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-08 00:00:00]) == ~U[2018-01-17 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-22 00:00:00]) == ~U[2018-01-31 18:00:00]
    end

    test "every other week, twice a week" do
      recurrence = %Weekly{start: ~U[2018-01-02 18:00:00], on: [:wednesday, :friday], every: 2}
      assert Recurrence.next(recurrence, ~U[2000-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 17:59:59]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-03 18:00:00]) == ~U[2018-01-05 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-04 18:00:00]) == ~U[2018-01-05 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-05 18:00:00]) == ~U[2018-01-17 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-18 18:00:00]) == ~U[2018-01-19 18:00:00]
    end

    test "every three weeks on a single day" do
      recurrence = %Weekly{start: ~U[2018-01-02 18:00:00], on: [:wednesday], every: 3}
      assert Recurrence.next(recurrence, ~U[2018-01-01 01:00:00]) == ~U[2018-01-03 18:00:00]
      assert Recurrence.next(recurrence, ~U[2018-01-04 01:00:00]) == ~U[2018-01-24 18:00:00]
    end

    test "fails when the days of week is invalid or empty" do
      assert_raise RuntimeError, "Invalid 'on' value for weekly recurrence: []", fn ->
        %Weekly{start: DateTime.utc_now, on: []} |> Recurrence.next
      end

      assert_raise RuntimeError, "Invalid 'on' value for weekly recurrence: [:foo]", fn ->
        %Weekly{start: DateTime.utc_now, on: [:foo]} |> Recurrence.next
      end
    end
  end

  defp sigil_U(ts, _) do
    NaiveDateTime.from_iso8601!(ts) |> DateTime.from_naive!("Etc/UTC")
  end
end
