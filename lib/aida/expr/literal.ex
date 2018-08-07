defmodule Aida.Expr.Literal do
  defstruct [:type, :value]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(literal) do
      case literal.type do
        :integer -> literal.value
        :string -> "'#{literal.value}'"
      end
    end

    def eval(literal, _context) do
      literal.value
    end
  end
end
