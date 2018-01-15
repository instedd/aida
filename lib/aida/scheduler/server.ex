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
    {state, delay} = dispatch()
    {:ok, state, delay}
  end

  @doc """
  Appoints a new task to the scheduler.

  Stores the task in the database and in the list of tasks in memory.
  """
  def handle_call({:appoint, name, ts, handler}, _from, %State{next_ts: next_ts} = state) do
    task = Task.create(name, ts, handler)
    ts = DateTime.to_unix(task.ts, :milliseconds)
    state = %{state | next_ts: min(next_ts, ts)}

    {:reply, :ok, state, next_delay(state)}
  end

  @doc """
  Does nothing. Used for testing purposes to synchronously wait until all messages are processed.
  """
  def handle_call(:flush, _from, state) do
    {:reply, :ok, state}
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

  defp next_delay(%State{next_ts: next_ts}) do
    now = DateTime.utc_now
    delay = next_ts - (now |> DateTime.to_unix(:milliseconds))
    max(delay, 0)
  end
end
