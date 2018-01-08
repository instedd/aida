defmodule Aida.Variable do
  alias Aida.{Bot, Variable.Override, Session}

  @type t :: %__MODULE__{
    name: String.t,
    values: Bot.message,
    overrides: [Override.t]
  }

  defstruct name: nil,
            values: %{},
            overrides: []

  defmodule Override do
    @type t :: %__MODULE__{
      relevant: Aida.Expr.t,
      values: Bot.message
    }
    defstruct relevant: nil,
              values: %{}
  end

  @spec resolve_value(t, Session.t) :: Bot.message
  def resolve_value(variable, session) do
    override =
      variable.overrides
      |> Enum.find(fn override ->
        try do
          override.relevant |> Aida.Expr.eval(session |> Session.expr_context(lookup_raises: true))
        rescue
          Aida.Expr.UnknownVariable -> false
        end
      end)

    if override do
      override.values
    else
      variable.values
    end
  end
end
