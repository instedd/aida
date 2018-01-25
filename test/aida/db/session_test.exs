defmodule Aida.DB.SessionTest do
  use Aida.DataCase
  alias Aida.DB.Session
  alias Aida.Repo

  @uuid "21280f3e-f1a9-4446-a171-82a85560bdfb"
  @uuid2 "87514f2d-9aa8-4d36-bbc7-c54e6447b2b9"

  test "can insert and retrieve sessions" do
    data = %{"foo" => 1, "bar" => 2}

    %Session{}
      |> Session.changeset(%{id: "session_id", uuid: @uuid, data: data})
      |> Repo.insert!

    [session] = Session |> Repo.all
    assert session.id == "session_id"
    assert session.uuid == @uuid
    assert session.data == data
  end

  test "cannot insert two sessions with same id" do
    %Session{}
      |> Session.changeset(%{id: "session_id", uuid: @uuid, data: %{}})
      |> Repo.insert!

    assert_raise Ecto.ConstraintError, fn ->
      %Session{}
        |> Session.changeset(%{id: "session_id", uuid: @uuid2, data: %{}})
        |> Repo.insert!
    end
  end

  # TODO: This should work
  # test "cannot insert two sessions with same uuid" do
  #   %Session{}
  #     |> Session.changeset(%{id: "session_id", uuid: @uuid, data: %{}})
  #     |> Repo.insert!

  #   assert_raise Ecto.ConstraintError, fn ->
  #     %Session{}
  #       |> Session.changeset(%{id: "session_id_2", uuid: @uuid, data: %{}})
  #       |> Repo.insert!
  #   end
  # end
end
