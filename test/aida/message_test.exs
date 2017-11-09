defmodule Aida.MessageTest do
  alias Aida.{Message, Session}
  use ExUnit.Case

  test "create new incoming message with new session" do
    message = Message.new("Hi!")
    assert %Message{
      session: %Session{is_new?: true},
      content: "Hi!",
      reply: []
    } = message
  end

  test "create new incoming message with existing session" do
    session = Session.new("9d0694e1-9245-4b9c-9984-7c37b39e1906", %{"foo" => "bar"})
    message = Message.new("Hi!", session)
    assert %Message{
      session: ^session,
      content: "Hi!",
      reply: []
    } = message
  end
end
