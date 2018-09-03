defmodule AidaWeb.Router do
  use AidaWeb, :router

  # Capture errors and report to Sentry
  # https://github.com/getsentry/sentry-elixir#setup-with-plug-or-phoenix
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug(:accepts, ["json"])

    plug(
      Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison
    )
  end

  pipeline :browser do
    plug(
      Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison
    )
  end

  pipeline :attachment do
    plug(
      Plug.Parsers,
      parsers: [:multipart],
      length: 25 * 1024 * 1024
    )
  end

  scope "/api", AidaWeb do
    pipe_through(:api)

    resources "/bots", BotController, except: [:new, :edit] do
      get("/session_data", SessionController, :session_data)

      resources "/sessions", SessionController, only: [:index] do
        get("/log", SessionController, :log)
        post("/send_message", SessionController, :send_message)
        post("/attachment", SessionController, :attachment)
        put("/forward_messages", SessionController, :forward_messages)
      end

      resources("/error_logs", ErrorLogController, only: [:index])
      get("/stats/usage_summary", SkillUsageController, :usage_summary)
      get("/stats/users_per_skill", SkillUsageController, :users_per_skill)
    end

    get("/image/:uuid", ImageController, :image)
    get("/version", VersionController, :version)
    get("/check_credentials", WitAiController, :check_credentials)
  end

  scope "/", AidaWeb do
    pipe_through(:browser)
    get("/callback/:provider", CallbackController, :callback)
    post("/callback/:provider", CallbackController, :callback)
    post("/callback/:provider/:bot_id", CallbackController, :callback)
    get("/content/image/:uuid", ImageController, :image)
  end

  scope "/", AidaWeb do
    pipe_through(:attachment)
    post("/content/image/:bot_id/:session_id", SessionController, :attachment)
  end
end
