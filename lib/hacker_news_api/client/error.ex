defmodule HackerNewsApi.Client.MediaTypeError do
  @moduledoc """
  Exception for media-type errors.
  """

  @type t :: %__MODULE__{}

  defexception [:message]

  @impl true
  def exception(:missing) do
    %__MODULE__{
      message: "content-type header missing in response"
    }
  end

  @impl true
  def exception(<<_::binary>> = unsupported) do
    %__MODULE__{
      message: "unsupported media-type: #{unsupported}"
    }
  end
end
