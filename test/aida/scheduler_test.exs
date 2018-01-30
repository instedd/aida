defmodule Aida.SchedulerTest do
  alias Aida.Scheduler
  use Aida.DataCase
  use Aida.TimeMachine
  use Aida.LogHelper

  defmodule TestHandler do
    @behaviour Aida.Scheduler.Handler

    def handle_scheduled_task(task_id, ts) do
      [id, pid] = String.split(task_id, "/")
      send String.to_atom(pid), {id, ts}
    end
  end

  setup do
    Scheduler.start_link
    pid = System.unique_integer([:positive])
    Process.register(self(), "#{pid}" |> String.to_atom)

    %{pid: pid}
  end

  test "schedule a task", %{pid: pid} do
    ts = within(days: 1)
    Scheduler.appoint("test_task/#{pid}", ts, TestHandler)

    time_travel(ts) do
      assert_receive {"test_task", ^ts}
    end
  end

  test "schedule two tasks", %{pid: pid} do
    ts1 = within(days: 1)
    ts2 = within(days: 2)
    Scheduler.appoint("test_task_1/#{pid}", ts1, TestHandler)
    Scheduler.appoint("test_task_2/#{pid}", ts2, TestHandler)

    time_travel(ts1) do
      assert_receive {"test_task_1", ^ts1}
    end

    time_travel(ts2) do
      assert_receive {"test_task_2", ^ts2}
    end
  end

  test "scheduled task is persisted" do
    ts = within(hours: 10)
    Scheduler.appoint("my_task", ts, TestHandler)

    assert [task] = Scheduler.Task |> Aida.Repo.all
    assert %Scheduler.Task{name: "my_task", ts: ^ts, handler: TestHandler} = task
  end

  test "load persisted tasks on startup", %{pid: pid} do
    Scheduler.stop

    ts = within(days: 1)
    %Scheduler.Task{name: "test_task/#{pid}", ts: ts, handler: TestHandler}
    |> Ecto.Changeset.change
    |> Aida.Repo.insert!

    Scheduler.start_link

    time_travel(ts) do
      assert_receive {"test_task", ^ts}
    end
  end

  test "continue loading from db when the queue is empty", %{pid: pid} do
    Scheduler.stop

    ts = within(days: 1)
    (1..10) |> Enum.each(fn id ->
      Scheduler.Task.create("test_task_#{id}/#{pid}", ts, TestHandler)
    end)

    Scheduler.start_link

    time_travel(ts) do
      (1..10) |> Enum.each(fn id ->
        task_id = "test_task_#{id}"
        assert_receive {^task_id, ^ts}
      end)
    end
  end

  test "do not enqueue in last position if there are more tasks in the db", %{pid: pid} do
    Scheduler.stop

    ts1 = within(days: 1)
    (1..10) |> Enum.each(fn id ->
      Scheduler.Task.create("test_task_1_#{id}/#{pid}", ts1, TestHandler)
    end)

    Scheduler.start_link

    ts2 = within(days: 2)
    Scheduler.appoint("test_task_2/#{pid}", ts2, TestHandler)

    time_travel(ts1) do
      (1..10) |> Enum.each(fn id ->
        task_id = "test_task_1_#{id}"
        assert_receive {^task_id, ^ts1}
      end)
    end
  end

  test "schedule many tasks for the same time", %{pid: pid} do
    ts1 = within(days: 1)
    (1..10) |> Enum.each(fn id ->
      Scheduler.appoint("test_task_1_#{id}/#{pid}", ts1, TestHandler)
    end)

    ts2 = within(days: 2)
    (1..10) |> Enum.each(fn id ->
      Scheduler.appoint("test_task_2_#{id}/#{pid}", ts2, TestHandler)
    end)

    time_travel(ts1) do
      (1..10) |> Enum.each(fn id ->
        task_id = "test_task_1_#{id}"
        assert_receive {^task_id, ^ts1}
      end)
    end

    time_travel(ts2) do
      (1..10) |> Enum.each(fn id ->
        task_id = "test_task_2_#{id}"
        assert_receive {^task_id, ^ts2}
      end)
    end
  end

  test "scheduled task is deleted after execution", %{pid: pid} do
    ts = within(days: 1)
    Scheduler.appoint("test_task/#{pid}", ts, TestHandler)

    time_travel(ts) do
      assert_receive {"test_task", ^ts}
    end

    assert [] = Scheduler.Task |> Aida.Repo.all
  end

  test "reschedule task to a later timestamp", %{pid: pid} do
    ts1 = within(days: 1)
    Scheduler.appoint("test_task/#{pid}", ts1, TestHandler)

    ts2 = within(days: 2)
    Scheduler.appoint("test_task/#{pid}", ts2, TestHandler)

    assert [task] = Scheduler.Task |> Aida.Repo.all
    task_id = "test_task/#{pid}"
    assert %Scheduler.Task{name: ^task_id, ts: ^ts2, handler: TestHandler} = task

    time_travel(ts1) do
      Scheduler.flush
      refute_received _
    end

    time_travel(ts2) do
      assert_receive {"test_task", ^ts2}
    end
  end

  test "schedule an already overdue task", %{pid: pid} do
    ts = DateTime.utc_now
    Scheduler.appoint("test_task/#{pid}", ts, TestHandler)

    assert_receive {"test_task", ^ts}

    Scheduler.flush
  end

  test "cancel a task", %{pid: pid} do
    ts = within(days: 1)
    Scheduler.appoint("test_task/#{pid}", ts, TestHandler)
    assert Scheduler.cancel("test_task/#{pid}") == :ok
    assert Scheduler.cancel("foo") == {:error, :not_found}

    time_travel(ts) do
      Scheduler.flush
      refute_received _
    end
  end

  test "do not crash when the task fails", %{pid: pid} do
    ts1 = within(days: 1)
    Scheduler.appoint("test_task_1/#{pid}", ts1, InvalidHandler)
    ts2 = within(days: 2)
    Scheduler.appoint("test_task_2/#{pid}", ts2, TestHandler)

    without_logging do
      time_travel(ts2) do
        assert_receive {"test_task_2", ^ts2}
      end
    end

    refute_received _
  end

  test "schedule a task to a distant future", %{pid: pid} do
    ts = within(years: 100)
    Scheduler.appoint("test_task/#{pid}", ts, TestHandler)

    time_travel(ts) do
      assert_receive {"test_task", ^ts}
    end
  end

  test "schedule a task to a distant future before starting the scheduler", %{pid: pid} do
    Scheduler.stop
    ts = within(years: 100)
    Scheduler.appoint("test_task/#{pid}", ts, TestHandler)
    Scheduler.start_link

    time_travel(ts) do
      assert_receive {"test_task", ^ts}
    end
  end
end
