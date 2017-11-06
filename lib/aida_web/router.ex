defmodule AidaWeb.Router do
  use AidaWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AidaWeb do
    pipe_through :api
  end
end
