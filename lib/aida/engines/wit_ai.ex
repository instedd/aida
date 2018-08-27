defmodule Aida.Engine.WitAi do
  alias __MODULE__
  alias Aida.{Bot, Skill}

  @type t :: %__MODULE__{
          auth_token: String.t()
        }

  defstruct auth_token: nil

  def check_credentials(%{"auth_token" => token}) do
    url = "https://api.wit.ai/message?v=20180815&q=hello"
    headers = %{"Authorization" => "Bearer #{token}"}

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, response} -> {:error, response.body |> Poison.decode!()}
      response -> {:error, response}
    end
  end

  def check_credentials(_), do: {:error, "Authorization token expected"}

  def delete_existing_entity_if_any(_auth_token, _bot_id), do: :ok
  def create_entity(_auth_token, _bot_id), do: :ok
  def upload_sample(_auth_token, _training_sentences, _value), do: :ok

  defimpl Aida.Engine, for: __MODULE__ do
    def update_training_set(%WitAi{auth_token: auth_token}, %Bot{skills: skills} = bot) do
      training_set =
        skills
        |> Enum.reduce([], fn skill, training_set ->
          case Skill.training_sentences(skill) do
            nil -> training_set
            sentences -> [{sentences, skill} | training_set]
          end
        end)

      # Just to be sure that there is nothing there contaminating its behavior
      WitAi.delete_existing_entity_if_any(auth_token, bot.id)

      WitAi.create_entity(auth_token, bot.id)

      training_set |> Enum.each(fn {sentences, skill} ->
        # only english is supported for now
        WitAi.upload_sample(auth_token, sentences["en"], Skill.id(skill))
      end)

      :ok
    end

    def confidence(_message), do: :ok
  end
end
