defmodule Aida.ErrorHandler do
  require Logger
  use Aida.ErrorLog

  def capture_exception(message, error, extra \\ []) do
    stacktrace = System.stacktrace()

    Sentry.capture_exception(
      error,
      stacktrace: stacktrace,
      extra: Enum.into(extra, %{}),
      result: :none
    )

    Logger.error("#{message}: #{Exception.format(:error, error, stacktrace)}")
    ErrorLog.write("#{message}: #{Exception.message(error)}")
  end

  def capture_message(message, extra \\ []) do
    sentry_capture(message, extra)
    Logger.warn("#{message} #{inspect(extra)}")
  end

  def log_error(message, extra \\ []) do
    sentry_capture(message, extra)
    ErrorLog.write(message)
  end

  defp sentry_capture(message, extra) do
    Sentry.capture_message(
      message,
      extra: Enum.into(extra, %{}),
      result: :none
    )
  end
end
