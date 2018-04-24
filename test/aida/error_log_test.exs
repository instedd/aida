defmodule Aida.ErrorLogTest do
  use Aida.DataCase
  alias Aida.{DB, ErrorLog, Repo}
  require Aida.ErrorLog

  describe "context" do
    test "is initially empty" do
      assert ErrorLog.current_context() == %{}
    end

    test "can be set for the current process" do
      ErrorLog.push_context(foo: 1)
      assert ErrorLog.current_context() == %{foo: 1}
    end

    test "context is merged with the existing one" do
      ErrorLog.push_context(foo: 1)
      ErrorLog.push_context(bar: 2)
      assert ErrorLog.current_context() == %{foo: 1, bar: 2}
    end

    test "pushing context returns the previous one" do
      assert ErrorLog.push_context(foo: 1) == %{}
      assert ErrorLog.push_context(bar: 2) == %{foo: 1}
    end

    test "replace context" do
      ErrorLog.push_context(foo: 1)
      ErrorLog.set_context(%{bar: 2})
      assert ErrorLog.current_context() == %{bar: 2}
    end

    test "set and restore context" do
      ErrorLog.context foo: 1 do
        assert ErrorLog.current_context() == %{foo: 1}

        ErrorLog.context bar: 2 do
          assert ErrorLog.current_context() == %{foo: 1, bar: 2}
        end

        assert ErrorLog.current_context() == %{foo: 1}
      end

      assert ErrorLog.current_context() == %{}
    end
  end

  describe "report errors" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!()
      {:ok, bot} = DB.create_bot(%{manifest: manifest})

      %{bot: bot}
    end

    test "log simple error for bot", %{bot: bot} do
      ErrorLog.context bot_id: bot.id do
        ErrorLog.write("Some error")
      end

      assert [error_log] = ErrorLog |> Repo.all()
      assert error_log.bot_id == bot.id
      assert error_log.message == "Some error"
    end

    test "log error for bot / session / skill", %{bot: bot} do
      session_id = "82795fdc-c64c-412b-a00f-b01421fbed61"
      skill_id = "c9ef260b-a746-4986-b11d-07f37dbd0210"

      ErrorLog.context bot_id: bot.id do
        ErrorLog.context session_id: session_id, skill_id: skill_id do
          ErrorLog.write("Some error")
        end
      end

      assert [error_log] = ErrorLog |> Repo.all()
      assert error_log.bot_id == bot.id
      assert error_log.session_id == session_id
      assert error_log.skill_id == skill_id
      assert error_log.message == "Some error"
    end
  end
end
