defmodule AidaWeb.VersionController do
  use AidaWeb, :controller

  def version(conn, _) do
    render(conn, "version.json", version: Application.get_env(:aida, :version))
  end
end
