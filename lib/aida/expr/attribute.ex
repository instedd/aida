defmodule Aida.Expr.Attribute do
  defstruct [:name]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(attr) do
      attr.name
    end

    def eval(attr, context) do
      context.attr_lookup.(attr.name)
    end
  end
end
