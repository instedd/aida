defmodule Aida.Unsubscribe do
  alias Aida.{Bot}

  @type t :: %__MODULE__{
          introduction_message: Bot.message(),
          keywords: %{},
          acknowledge_message: Bot.message()
        }

  defstruct introduction_message: %{},
            keywords: %{},
            acknowledge_message: %{}
end
