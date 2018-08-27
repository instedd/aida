defmodule Aida.WitAi do
  @type t :: %__MODULE__{
          auth_token: String.t()
        }

  defstruct auth_token: nil
end
