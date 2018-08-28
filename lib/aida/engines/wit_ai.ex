defmodule Aida.Engine.WitAi do
  alias __MODULE__
  alias Aida.{Bot, Skill}

  @type t :: %__MODULE__{
          auth_token: String.t()
        }

  defstruct auth_token: nil
  @api_version "20180815"
  @base_wit_ai_api_url "https://api.wit.ai"

  defp auth_headers(token) do
    %{"Authorization" => "Bearer #{token}"}
  end

  defp payload_headers(token) do
    %{
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  def check_credentials(nil), do: {:error, "Authorization token expected"}

  def check_credentials(token) do
    url = "#{@base_wit_ai_api_url}/message?v=#{@api_version}&q=hello"

    HTTPoison.get(url, auth_headers(token))
    |> handle
  end

  def delete_existing_entity_if_any(token, bot_id) do
    url = "#{@base_wit_ai_api_url}/entities/#{bot_id}?v=#{@api_version}"

    HTTPoison.delete(url, auth_headers(token))

    :ok
  end

  def create_entity(token, bot_id) do
    url = "#{@base_wit_ai_api_url}/entities?v=#{@api_version}"

    body = %{"id" => bot_id} |> Poison.encode!()

    HTTPoison.post(url, body, payload_headers(token))
    |> handle
  end

  def upload_sample(token, bot_id, training_sentences, skill_id) do
    url = "#{@base_wit_ai_api_url}/samples?v=#{@api_version}"

    body =
      training_sentences
      |> Enum.map(fn text ->
        %{
          "text" => text,
          "entities" => [
            %{
              "entity" => bot_id,
              "value" => skill_id
            }
          ]
        }
      end)
      |> Poison.encode!()

    HTTPoison.post(url, body, payload_headers(token))
    |> handle
  end

  defp handle(response) do
    case response do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, response} -> {:error, response.body |> Poison.decode!()}
      response -> {:error, response}
    end
  end

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

      training_set
      |> Enum.each(fn {sentences, skill} ->
        # only english is supported for now
        WitAi.upload_sample(auth_token, bot.id, sentences["en"], Skill.id(skill))
      end)

      :ok
    end

    def confidence(_message), do: :ok
  end
end
