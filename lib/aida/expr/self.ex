defmodule Aida.Expr.Self do
  defstruct []

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(_self) do
      "."
    end

    def eval(_self, context) do
      context.self
    end
  end
end
