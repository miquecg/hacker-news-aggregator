defmodule HackerNewsWeb.ErrorView do
  use HackerNewsWeb, :view

  defp render_template("error.json", %{message: message}, _conn), do: %{error: message}
end
