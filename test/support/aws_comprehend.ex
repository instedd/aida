defmodule Aida.Skill.LanguageDetector.AwsComprehend do
  def detect_dominant_language("Hi!") do
    [%{language: "en", score: 0.5}]
  end

  def detect_dominant_language("português") do
    [%{language: "pt", score: 0.5}]
  end

  def detect_dominant_language("que bien que anda esto") do
    [%{language: "es", score: 0.5}]
  end

  def detect_dominant_language("Здравствуй!") do
    [%{language: "ru", score: 0.5}]
  end

  def detect_dominant_language("") do
    []
  end
end
