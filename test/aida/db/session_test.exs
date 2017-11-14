defmodule Aida.DB.SessionTest do
  use Aida.DataCase
  alias Aida.DB.Session
  alias Aida.Repo

  test "can insert and retrieve sessions" do
    data = %{"foo" => 1, "bar" => 2}

    %Session{}
      |> Session.changeset(%{id: "session_id", data: data})
      |> Repo.insert!

    [session] = Session |> Repo.all
    assert session.id == "session_id"
    assert session.data == data
  end

  test "cannot insert two sessions with same id" do
    %Session{}
      |> Session.changeset(%{id: "session_id", data: %{}})
      |> Repo.insert!

    assert_raise Ecto.ConstraintError, fn ->
      %Session{}
        |> Session.changeset(%{id: "session_id", data: %{}})
        |> Repo.insert!
    end
  end
end
