defmodule HackerNewsApi.Error.Params do
  @moduledoc """
  Exception for invalid params.
  """

  defexception [:module, :params, :error]

  @type t :: %__MODULE__{
          module: module(),
          params: [
            {param :: atom(), value :: term()},
            ...
          ],
          error: atom() | String.t()
        }

  @impl true
  def message(exception) do
    lines =
      exception.params
      |> Enum.map(&build_line/1)
      |> Enum.join("\n")

    """
    invalid params for #{exception.module}
    #{lines}
    #{exception.error}
    """
  end

  defp build_line({param, value}), do: "#{param} got value: #{inspect(value)}"
end
