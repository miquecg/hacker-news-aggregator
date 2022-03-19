defmodule HackerNewsWeb do
  @moduledoc """
  The entrypoint for defining the web interface.
  """

  def router do
    quote do
      @plug_init_mode Application.compile_env(:hacker_news, :plug_init_mode, :compile)

      use Plug.Router, init_mode: @plug_init_mode

      alias HackerNewsWeb.StoryView
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
