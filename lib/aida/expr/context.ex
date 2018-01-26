defmodule Aida.Expr.Context do
  defstruct self: nil,
            var_lookup: nil,
            attr_lookup: nil,
            functions: %{}

  def add_function(context, name, body) do
    %{context | functions: context.functions |> Map.put(name, body)}
  end
end
