defmodule Aida.Expr.UnaryOp do
  defstruct [:op, :value]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(un) do
      "#{un.op}(#{un.value |> Aida.Expr.to_string()})"
    end

    def eval(un, context) do
      value = un.value |> Aida.Expr.eval(context)

      case un.op do
        :- -> -value
      end
    end
  end
end
