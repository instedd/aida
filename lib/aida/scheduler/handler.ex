defmodule Aida.Scheduler.Handler do
  @callback handle_scheduled_task(name :: String.t(), ts :: DateTime.t()) :: :ok
end
