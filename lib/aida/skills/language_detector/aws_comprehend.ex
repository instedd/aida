if Mix.env() != :test do
  defmodule Aida.Skill.LanguageDetector.AwsComprehend do
    def detect_dominant_language("") do
      []
    end

    def detect_dominant_language(text) do
      url = "https://comprehend.us-east-1.amazonaws.com/"

      headers = %{
        "Content-Type" => "application/json",
        "Content-Encoding" => "amz-1.0",
        "X-Amz-Target" => "com.amazonaws.comprehend.Comprehend_20171127.DetectDominantLanguage"
      }

      body = %{Text: text} |> Poison.encode!()

      {:ok, %{} = sig_data, _} =
        Sigaws.sign_req(
          url,
          region: "us-east-1",
          service: "comprehend",
          access_key: System.get_env("AWS_ACCESS_KEY_ID"),
          secret: System.get_env("AWS_SECRET_ACCESS_KEY"),
          method: "POST",
          headers: headers,
          body: body
        )

      headers = Map.merge(headers, sig_data)
      %{"Languages" => languages} = HTTPoison.post!(url, body, headers).body |> Poison.decode!()

      languages
      |> Enum.map(fn %{"LanguageCode" => lang, "Score" => score} ->
        %{language: lang, score: score}
      end)
      |> Enum.sort_by(&Map.get(&1, :score), &>=/2)
    end
  end
end
