defmodule Aida.Scheduler.Server do
  use GenServer
  alias Aida.Scheduler.Task

  @config Application.get_env(:aida, Aida.Scheduler, [])
  @batch_size @config |> Keyword.get(:batch_size, 100)

  defmodule State do
    @type t :: %__MODULE__{
      next_ts: nil | pos_integer
    }

    defstruct [:next_ts]
  end

  @doc """
  Initializes the server loading the existing tasks from the database
  """
  def init([]) do
    Aida.PubSub.subscribe_scheduler
    {state, delay} = dispatch()
    {:ok, state, delay}
  end

  @doc """
  Does nothing. Used for testing purposes to synchronously wait until all messages are processed.
  """
  def handle_call(:flush, _from, state) do
    {:reply, :ok, state, next_delay(state)}
  end

  @doc """
  Receives the PubSub notification about a new task. The notification includes
  the timestamp of the task.
  """
  def handle_info({:task_created, ts}, %State{next_ts: next_ts} = state) do
    state = %{state | next_ts: min(next_ts, ts)}
    {:noreply, state, next_delay(state)}
  end

  @doc """
  Receives the :timeout event and processes overdue tasks
  """
  def handle_info(:timeout, _state) do
    {state, delay} = dispatch()
    {:noreply, state, delay}
  end

  # Loads the next batch of tasks and run the ones already overdue.
  # Returns a tuple with the state and next delay
  @spec dispatch() :: {State.t, timeout()}
  defp dispatch do
    case Task.load(@batch_size) do
      [] -> {%State{next_ts: nil}, :infinity}
      tasks -> dispatch(tasks)
    end
  end

  defp dispatch([]), do: dispatch()

  defp dispatch([task | tasks]) do
    now = DateTime.utc_now
    case DateTime.compare(task.ts, now) do
      :gt ->
        next_ts = DateTime.to_unix(task.ts, :milliseconds)
        delay = next_ts - (now |> DateTime.to_unix(:milliseconds))
        {%State{next_ts: next_ts}, delay}

      _ ->
        task.handler.handle_scheduled_task(task.name, task.ts)
        task |> Task.delete

        dispatch(tasks)
    end
  end

  defp next_delay(%State{next_ts: nil}), do: :infinity

  defp next_delay(%State{next_ts: next_ts}) do
    now = DateTime.utc_now
    delay = next_ts - (now |> DateTime.to_unix(:milliseconds))
    max(delay, 0)
  end
end
