defmodule AidaWeb.Static do
  @behaviour Plug
  alias Plug.Static.InvalidPathError

  def init(opts) do
    Plug.Static.init(opts)
  end

  # Default Plug.Static throws an (Plug.Static.InvalidPathError)
  # when parsing a route that includes a session_id.
  # This wrapper was made in order to handle that error.
  def call(conn, opts) do
    try do
      Plug.Static.call(conn, opts)
    rescue
      InvalidPathError -> conn
    end
  end
end
