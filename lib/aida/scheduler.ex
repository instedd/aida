defmodule Aida.Scheduler do
  @server_ref {:global, __MODULE__}

  @spec start_link() :: GenServer.on_start
  def start_link() do
    GenServer.start_link(Aida.Scheduler.Server, [], name: @server_ref)
  end

  def stop do
    GenServer.stop(@server_ref)
  end

  @spec appoint(String.t, DateTime.t, :atom) :: :ok
  def appoint(name, ts, handler) do
    GenServer.call(@server_ref, {:appoint, name, ts, handler})
  end

  def flush do
    GenServer.call(@server_ref, :flush)
  end
end
