defmodule HackerNewsApi.Error.MediaType do
  @moduledoc """
  Exception for media-type errors.
  """

  defexception [:message]

  @type t :: %__MODULE__{}

  @impl true
  def exception(:missing) do
    %__MODULE__{
      message: "content-type header missing in response"
    }
  end

  @impl true
  def exception(info) do
    {type_subtype, charset} = Access.fetch!(info, :unsupported)

    %__MODULE__{
      message: "unsupported media-type: #{type_subtype};charset=#{charset}"
    }
  end
end
