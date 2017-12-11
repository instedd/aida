defmodule Aida.ScheduledMessagesTest do
  alias Aida.{Skill.ScheduledMessages, DelayedMessage}
  use ExUnit.Case

  describe "scheduled messages" do
    setup do
      %{skill: %ScheduledMessages{
          id: "inactivity_check",
          name: "Inactivity Check",
          schedule_type: "since_last_incoming_message"
        }}
    end

    test "schedules for half the delay interval", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: "180"}]}
      assert ScheduledMessages.delay(skill) == :timer.minutes(90)
    end

    test "schedules for 24hs as max value", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: "#{24*60*3}"}]}
      assert ScheduledMessages.delay(skill) == :timer.hours(24)
    end

    test "schedules for 20 minutes as min value", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: "1"}]}
      assert ScheduledMessages.delay(skill) == :timer.minutes(20)
    end
  end
end
