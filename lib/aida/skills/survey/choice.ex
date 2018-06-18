defmodule Aida.Skill.Survey.Choice do
  alias Aida.Message
  alias __MODULE__
  use Aida.ErrorLog

  @type t :: %__MODULE__{
    name: String.t(),
    labels: %{},
    attributes: nil | %{required(String.t) => String.t | integer}
  }

  defstruct name: "",
            labels: %{},
            attributes: nil


  def name(%Choice{name: name}) do
    name
  end

  @spec available?(choice :: t, filter :: Aida.Expr.t, message :: Aida.Message.t) :: boolean
  def available?(_choice, nil, _message), do: true
  def available?(choice, filter, message) do
    attr_lookup = &attr_lookup(choice, &1)
    context = message
      |> Message.expr_context(attr_lookup: attr_lookup, lookup_raises: true, self: choice.name)

    try do
      filter |> Aida.Expr.eval(context)
    rescue
      error ->
        ErrorLog.write(Exception.message(error))
        false
    end
  end

  defp attr_lookup(choice, attr_name) do
    case choice.attributes && Map.get(choice.attributes, attr_name) do
      nil ->
        raise Aida.Expr.UnknownAttributeError.exception(attr_name)
      value ->
        value
    end
  end
end
