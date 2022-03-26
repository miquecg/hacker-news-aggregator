defmodule HackerNewsApi.Client.Response do
  @moduledoc """
  Struct that represents an HTTP response.
  """

  alias __MODULE__
  alias HackerNewsApi.Error

  defstruct [:status, :headers, :raw_body, :body]

  @type header :: {name :: String.t(), value :: String.t()}

  @type t :: %__MODULE__{
          status: 100..599,
          headers: [header],
          raw_body: binary(),
          body: term()
        }

  @typep ok :: {:ok, t}
  @typep error :: {:error, Error.Params.t()}

  @spec new!(keyword()) :: t | no_return()
  def new!(params) do
    case new(params) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  @spec new(keyword()) :: ok | error
  def new(params) do
    case build(params, %{}) do
      %{} = response ->
        {:ok, response}

      {:error, message} ->
        error = build_error(message, params)
        {:error, error}
    end
  end

  defp build([], acc) do
    case struct(__MODULE__, acc) do
      %{status: nil} -> {:error, "missing HTTP status code"}
      response -> response
    end
  end

  defp build([{:status, code} | rest], acc) when code in 100..599 do
    build(rest, Map.put(acc, :status, code))
  end

  defp build([{:status, _unknown} | _], _) do
    {:error, "unknown HTTP status code"}
  end

  defp build([{:headers, headers} | rest], acc) do
    if Enum.all?(headers, &match?({_, _}, &1)) do
      build(rest, Map.put(acc, :headers, headers))
    else
      {:error, "headers must be two-element tuples"}
    end
  end

  defp build([{:raw_body, <<_::binary>> = raw} | rest], acc) do
    build(rest, Map.put(acc, :raw_body, raw))
  end

  defp build([{:raw_body, _} | _], _) do
    {:error, "raw body must be a binary"}
  end

  defp build([{:body, body} | rest], acc) do
    build(rest, Map.put(acc, :body, body))
  end

  defp build_error(message, params) do
    %Error.Params{
      module: __MODULE__,
      params: params,
      error: message
    }
  end
end
