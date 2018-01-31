defmodule Aida.ErrorHandler do
  require Logger

  def capture_exception(message, error, extra \\ []) do
    stacktrace = System.stacktrace()

    Sentry.capture_exception(
      error,
      stacktrace: stacktrace,
      extra: Enum.into(extra, %{}),
      result: :none
    )

    Logger.error("#{message}: #{Exception.format(:error, error, stacktrace)}")
  end

  def capture_message(message, extra \\ []) do
    Sentry.capture_message(
      message,
      extra: Enum.into(extra, %{}),
      result: :none
    )

    Logger.warn("#{message} #{inspect extra}")
  end
end
