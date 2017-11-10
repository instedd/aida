defmodule Aida.Bot do
  alias Aida.{FrontDesk, Variable}
  @type message :: map

  @type t :: %__MODULE__{
    id: String.t,
    languages: [String.t],
    front_desk: FrontDesk.t,
    skills: [map],
    variables: [Variable.t],
    channels: []
  }

  defstruct id: nil,
            languages: [],
            front_desk: %FrontDesk{},
            skills: [],
            variables: [],
            channels: []
end
