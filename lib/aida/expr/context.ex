defmodule Aida.Expr.Context do
  defstruct self: nil,
            var_lookup: nil,
            attr_lookup: nil,
            functions: %{}
end
