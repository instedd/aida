defmodule AidaWeb.Router do
  use AidaWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AidaWeb do
    pipe_through :api
    resources "/bots", BotController, except: [:new, :edit]
    get "/version", VersionController, :version
    get "/stats/usage_summary", SkillUsageController, :usage_summary
    get "/stats/users_per_skill", SkillUsageController, :users_per_skill
  end

  scope "/", AidaWeb do
    get "/callback/:provider", CallbackController, :callback
    post "/callback/:provider", CallbackController, :callback
  end
end
