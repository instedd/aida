defmodule AidaWeb.VersionView do
  use AidaWeb, :view

  def render("version.json", %{version: version}) do
    %{data: version}
  end
end
