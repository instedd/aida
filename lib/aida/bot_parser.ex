defmodule Aida.BotParser do
  alias Aida.{Bot, FrontDesk, Skill.KeywordResponder, Variable, Channel.Facebook}

  @spec parse(id :: String.t, manifest :: map) :: Bot.t
  def parse(id, manifest) do
    %Bot{
      id: id,
      languages: manifest["languages"],
      front_desk: parse_front_desk(manifest["front_desk"]),
      skills: manifest["skills"] |> Enum.map(&parse_skill/1),
      variables: manifest["variables"] |> Enum.map(&parse_variable/1),
      channels: manifest["channels"] |> Enum.map(&parse_channel/1)
    }
  end

  @spec parse_front_desk(front_desk :: map) :: FrontDesk.t
  defp parse_front_desk(front_desk) do
    %FrontDesk{
      threshold: front_desk["threshold"],
      greeting: front_desk["greeting"]["message"],
      introduction: front_desk["introduction"]["message"],
      not_understood: front_desk["not_understood"]["message"],
      clarification: front_desk["clarification"]["message"]
    }
  end

  @spec parse_variable(var :: map) :: Variable.t
  defp parse_variable(var) do
    %Variable{
      name: var["name"],
      values: var["values"]
    }
  end

  defp parse_skill(%{"type" => "keyword_responder"} = skill) do
    %KeywordResponder{
      explanation: skill["explanation"],
      clarification: skill["clarification"],
      keywords: skill["keywords"],
      response: skill["response"]
    }
  end

  defp parse_channel(%{"type" => "facebook"} = skill) do
    %Facebook{
      page_id: skill["page_id"],
      verify_token: skill["verify_token"],
      access_token: skill["access_token"]
    }
  end
end
