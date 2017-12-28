defmodule Aida.Expr.Variable do
  defstruct [:name]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(var) do
      "${#{var.name}}"
    end

    def eval(var, context) do
      context.lookup.(var.name)
    end
  end
end
