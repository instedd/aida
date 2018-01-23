defmodule Aida.TimeMachine do
  alias Aida.Scheduler

  defmacro __using__(_) do
    quote do
      import Mock
      import Aida.TimeMachine
    end
  end

  defmacro time_travel(ts, do: block) do
    quote do
      now = unquote(ts)
      with_mock DateTime, [:passthrough], [utc_now: fn -> now end] do
        # Make sure no messages were received before this time travel
        refute_received _

        scheduler_pid = GenServer.whereis({:global, Scheduler})

        if scheduler_pid do
          # Simulate a :timeout event on the server
          send scheduler_pid, :timeout

          # Wait until all the messages are processed
          Scheduler.flush
        end

        # Run the test block
        unquote(block)
      end
    end
  end

  def within(shift) do
    Timex.shift(DateTime.utc_now, shift)
  end
end
