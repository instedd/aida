defmodule Aida.Expr.Context do
  defstruct self: nil,
            var_lookup: nil,
            attr_lookup: nil,
            functions: %{}

  def new(params \\ []) do
    __MODULE__
      |> struct(
        self: params[:self],
        var_lookup: Keyword.get(params, :var_lookup, fn name -> raise Aida.Expr.UnknownVariableError.exception(name) end),
        attr_lookup: Keyword.get(params, :attr_lookup, fn name -> raise Aida.Expr.UnknownAttributeError.exception(name) end),
        functions: Keyword.get(params, :functions, %{})
      )
  end

  def add_function(context, name, body) do
    %{context | functions: context.functions |> Map.put(name, body)}
  end
end
