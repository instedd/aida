defmodule Aida.WitAi do
  alias __MODULE__
  alias Aida.{Bot, ErrorLog, Skill, Message}

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
    |> parse
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
    |> parse
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
    |> parse
  end

  defp parse(response) do
    case response do
      {:ok, %{status_code: 200} = response} -> {:ok, response.body |> Poison.decode!()}
      {:ok, response} -> {:error, response.body |> Poison.decode!()}
      response -> {:error, response}
    end
  end

  @spec update_training_set(engine :: Aida.WitAi.t(), bot :: Aida.Bot.t()) :: :ok | {:error, %{}}
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
    delete_existing_entity_if_any(auth_token, bot.id)

    create_entity(auth_token, bot.id)

    training_set
    |> Enum.each(fn {sentences, skill} ->
      # only english is supported for now
      upload_sample(auth_token, bot.id, sentences["en"], Skill.id(skill))
    end)

    :ok
  end

  def update_training_set(_, _), do: :ok

  def confidence(%{bot: %{natural_language_interface: nil}}), do: []

  def confidence(%{bot: bot} = message) do
    case interpret_message(
           bot.natural_language_interface.auth_token,
           message |> Message.text_content()
         ) do
      {:ok, response} ->
        translate_to_skill_confidences(
          response["entities"][String.replace(bot.id, "-", "_")],
          bot
        )

      {_, response} ->
        ErrorLog.write("Bad response from Wit.Ai: #{response}")
        []
    end
  end

  defp translate_to_skill_confidences(nil, _), do: []

  defp translate_to_skill_confidences(entities, bot) do
    entities
    |> Enum.map(fn %{"confidence" => confidence, "value" => skill_id} ->
      skill = bot.skills |> Enum.find(fn skill -> skill.id == skill_id end)
      %{confidence: confidence, skill: skill}
    end)
  end

  defp interpret_message(token, message) do
    url = URI.encode("#{@base_wit_ai_api_url}/message?v=#{@api_version}&q=#{message}")

    HTTPoison.get(url, auth_headers(token))
    |> parse
  end
end
