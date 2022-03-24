defmodule HackerNewsApi.Client do
  @moduledoc """
  Behaviour that HTTP clients must adhere to.
  """

  alias __MODULE__.Response
  alias HackerNewsApi.Resource

  @type return :: return(Response.t())
  @type return(t) :: {:ok, t} | {:error, Exception.t()}

  @type media_type :: String.t()
  @type decoder :: (body :: binary() -> return(term()))
  @type option :: {:decode, {media_type, decoder}}
  @type opts :: [option]

  @callback do_request(Resource.t(), opts) :: return
end
