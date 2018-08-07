defmodule Aida.RecurrenceTest do
  alias Aida.Recurrence
  alias Aida.Recurrence.{Daily, Weekly, Monthly}
  use ExUnit.Case
  use Aida.TimeMachine

  describe "daily recurrence" do
    test "defaults to every 1 day" do
      start = DateTime.utc_now()
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
      start = DateTime.utc_now()

      assert %Weekly{start: start, on: [:monday]} == %Weekly{
               start: start,
               on: [:monday],
               every: 1
             }
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
        %Weekly{start: DateTime.utc_now(), on: []} |> Recurrence.next()
      end

      assert_raise RuntimeError, "Invalid 'on' value for weekly recurrence: [:foo]", fn ->
        %Weekly{start: DateTime.utc_now(), on: [:foo]} |> Recurrence.next()
      end
    end
  end

  describe "monthly recurrence" do
    test "defaults to every 1 week" do
      start = DateTime.utc_now()
      assert %Monthly{start: start, each: 10} == %Monthly{start: start, each: 10, every: 1}
    end

    test "every month on the 1st" do
      recurrence = %Monthly{start: ~U[2018-01-01 18:00:00], each: 1}

      assert_recurrence(recurrence, ~U[2017-01-01 00:00:00], [hours: 11], [
        ~U[2018-01-01 18:00:00],
        ~U[2018-02-01 18:00:00],
        ~U[2018-03-01 18:00:00],
        ~U[2018-04-01 18:00:00],
        ~U[2018-05-01 18:00:00],
        ~U[2018-06-01 18:00:00],
        ~U[2018-07-01 18:00:00],
        ~U[2018-08-01 18:00:00],
        ~U[2018-09-01 18:00:00],
        ~U[2018-10-01 18:00:00],
        ~U[2018-11-01 18:00:00],
        ~U[2018-12-01 18:00:00],
        ~U[2019-01-01 18:00:00],
        ~U[2019-02-01 18:00:00]
      ])
    end

    test "every month on a different (greater) day than start" do
      recurrence = %Monthly{start: ~U[2018-01-01 18:00:00], each: 10}
      assert Recurrence.next(recurrence, ~U[2018-02-01 00:00:00]) == ~U[2018-02-10 18:00:00]

      assert_recurrence(recurrence, ~U[2017-01-01 00:00:00], [hours: 11], [
        ~U[2018-01-10 18:00:00],
        ~U[2018-02-10 18:00:00],
        ~U[2018-03-10 18:00:00],
        ~U[2018-04-10 18:00:00],
        ~U[2018-05-10 18:00:00],
        ~U[2018-06-10 18:00:00],
        ~U[2018-07-10 18:00:00],
        ~U[2018-08-10 18:00:00],
        ~U[2018-09-10 18:00:00],
        ~U[2018-10-10 18:00:00],
        ~U[2018-11-10 18:00:00],
        ~U[2018-12-10 18:00:00],
        ~U[2019-01-10 18:00:00],
        ~U[2019-02-10 18:00:00]
      ])
    end

    test "every month on a different (greater) day not existing in every month" do
      recurrence = %Monthly{start: ~U[2018-01-01 18:00:00], each: 31}

      assert_recurrence(recurrence, ~U[2017-01-01 00:00:00], [hours: 11], [
        ~U[2018-01-31 18:00:00],
        ~U[2018-03-31 18:00:00],
        ~U[2018-05-31 18:00:00],
        ~U[2018-07-31 18:00:00],
        ~U[2018-08-31 18:00:00],
        ~U[2018-10-31 18:00:00],
        ~U[2018-12-31 18:00:00],
        ~U[2019-01-31 18:00:00],
        ~U[2019-03-31 18:00:00],
        ~U[2019-05-31 18:00:00],
        ~U[2019-07-31 18:00:00],
        ~U[2019-08-31 18:00:00],
        ~U[2019-10-31 18:00:00],
        ~U[2019-12-31 18:00:00]
      ])
    end

    test "every month on a different (greater) day not existing in the month of start" do
      recurrence = %Monthly{start: ~U[2018-02-01 18:00:00], each: 31}

      assert_recurrence(recurrence, ~U[2017-01-01 00:00:00], [hours: 11], [
        ~U[2018-03-31 18:00:00],
        ~U[2018-05-31 18:00:00],
        ~U[2018-07-31 18:00:00],
        ~U[2018-08-31 18:00:00],
        ~U[2018-10-31 18:00:00],
        ~U[2018-12-31 18:00:00],
        ~U[2019-01-31 18:00:00],
        ~U[2019-03-31 18:00:00],
        ~U[2019-05-31 18:00:00],
        ~U[2019-07-31 18:00:00],
        ~U[2019-08-31 18:00:00],
        ~U[2019-10-31 18:00:00],
        ~U[2019-12-31 18:00:00],
        ~U[2020-01-31 18:00:00]
      ])
    end

    test "every month on a different (lesser) day than start" do
      recurrence = %Monthly{start: ~U[2018-01-10 18:00:00], each: 5}

      assert_recurrence(recurrence, ~U[2017-01-01 00:00:00], [hours: 11], [
        ~U[2018-02-05 18:00:00],
        ~U[2018-03-05 18:00:00],
        ~U[2018-04-05 18:00:00]
      ])
    end

    test "every other month on the 1st" do
      recurrence = %Monthly{start: ~U[2018-01-10 18:00:00], each: 1, every: 2}

      assert_recurrence(recurrence, ~U[2017-01-01 00:00:00], [hours: 11], [
        ~U[2018-02-01 18:00:00],
        ~U[2018-04-01 18:00:00],
        ~U[2018-06-01 18:00:00],
        ~U[2018-08-01 18:00:00],
        ~U[2018-10-01 18:00:00],
        ~U[2018-12-01 18:00:00],
        ~U[2019-02-01 18:00:00],
        ~U[2019-04-01 18:00:00],
        ~U[2019-06-01 18:00:00]
      ])
    end

    test "every five months" do
      recurrence = %Monthly{start: ~U[2018-01-10 18:00:00], each: 10, every: 5}

      assert_recurrence(recurrence, ~U[2017-01-01 00:00:00], [hours: 11], [
        ~U[2018-01-10 18:00:00],
        ~U[2018-06-10 18:00:00],
        ~U[2018-11-10 18:00:00],
        ~U[2019-04-10 18:00:00],
        ~U[2019-09-10 18:00:00],
        ~U[2020-02-10 18:00:00],
        ~U[2020-07-10 18:00:00],
        ~U[2020-12-10 18:00:00],
        ~U[2021-05-10 18:00:00]
      ])
    end

    test "every two months on a day not available on every month" do
      recurrence = %Monthly{start: ~U[2014-12-10 18:00:00], each: 29, every: 2}
      assert Recurrence.next(recurrence, ~U[2014-12-29 18:00:00]) == ~U[2015-04-29 18:00:00]

      assert_recurrence(recurrence, ~U[2014-01-01 00:00:00], [hours: 11], [
        ~U[2014-12-29 18:00:00],
        ~U[2015-04-29 18:00:00],
        ~U[2015-06-29 18:00:00],
        ~U[2015-08-29 18:00:00],
        ~U[2015-10-29 18:00:00],
        ~U[2015-12-29 18:00:00],
        ~U[2016-02-29 18:00:00],
        ~U[2016-04-29 18:00:00]
      ])
    end
  end

  defp assert_recurrence(_recurrence, _start, _step, []), do: :ok

  defp assert_recurrence(recurrence, start, step, [goal | goals] = all_goals) do
    next = Recurrence.next(recurrence, start)
    # IO.puts "#{start} -> #{next}"
    assert next == goal,
           "next of #{start} gives #{next} instead of #{goal}\n" <>
             "assert Recurrence.next(recurrence, ~U[#{start |> DateTime.to_naive()}]) == ~U[#{
               goal |> DateTime.to_naive()
             }]"

    start = Timex.shift(start, step)

    if DateTime.compare(start, goal) == :lt do
      assert_recurrence(recurrence, start, step, all_goals)
    else
      assert_recurrence(recurrence, goal, step, goals)
    end
  end

  defp sigil_U(ts, _) do
    NaiveDateTime.from_iso8601!(ts) |> DateTime.from_naive!("Etc/UTC")
  end
end
