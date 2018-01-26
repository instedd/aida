defmodule Aida.DataTable do
  @type t :: %__MODULE__{
    name: String.t,
    columns: [String.t],
    data: [[String.t]]
  }

  defstruct [:name, :columns, :data]
end
