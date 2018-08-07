defmodule Aida.Scheduler do
  alias Aida.Scheduler.Task
  @server_ref {:global, __MODULE__}

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenServer.start_link(Aida.Scheduler.Server, [], name: @server_ref)
  end

  def stop do
    GenServer.stop(@server_ref)
  end

  @spec appoint(String.t(), DateTime.t(), atom) :: :ok
  def appoint(name, ts, handler) do
    task = Task.create(name, ts, handler)
    ts = DateTime.to_unix(task.ts, :milliseconds)
    Aida.PubSub.broadcast(task_created: ts)
    :ok
  end

  @spec cancel(String.t()) :: :ok | {:error, :not_found}
  def cancel(name) do
    Task.delete_by_name(name)
  end

  def flush do
    GenServer.call(@server_ref, :flush)
  end
end
