defmodule AidaWeb.Router do
  use AidaWeb, :router

  # Capture errors and report to Sentry
  # https://github.com/getsentry/sentry-elixir#setup-with-plug-or-phoenix
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AidaWeb do
    pipe_through :api
    resources "/bots", BotController, except: [:new, :edit] do
      get "/session_data", SessionController, :session_data
      resources "/sessions", SessionController, only: [:index] do
        get "/log", SessionController, :log
        post "/send_message", SessionController, :send_message
      end
      get "/stats/usage_summary", SkillUsageController, :usage_summary
      get "/stats/users_per_skill", SkillUsageController, :users_per_skill
    end
    get "/image/:uuid", ImageController, :image
    get "/content/image/:uuid", ImageController, :image
    get "/version", VersionController, :version
  end

  scope "/", AidaWeb do
    get "/callback/:provider", CallbackController, :callback
    post "/callback/:provider", CallbackController, :callback
  end
end
