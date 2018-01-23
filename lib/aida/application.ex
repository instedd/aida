defmodule Aida.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Aida.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AidaWeb.Endpoint, []),
      # Start your own worker by calling: Aida.Worker.start_link(arg1, arg2, arg3)
      # worker(Aida.Worker, [arg1, arg2, arg3]),
    ]

    children = if Mix.env != :test && !IEx.started? do
      children ++ [
        worker(Aida.JsonSchema, []),
        worker(Aida.ChannelRegistry, []),
        worker(Aida.BotManager, []),
        worker(Aida.SessionStore, []),
        worker(Aida.Scheduler, [])
      ]
    else
      children
    end

    # Capture all errors and report to Sentry
    # https://github.com/getsentry/sentry-elixir#capture-all-exceptions
    :ok = :error_logger.add_report_handler(Sentry.Logger)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Aida.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AidaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
