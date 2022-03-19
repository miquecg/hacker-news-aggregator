defmodule HackerNewsWeb do
  @moduledoc """
  The entrypoint for defining the web interface.
  """

  alias HackerNewsWeb.StoryView

  def router do
    quote do
      @plug_init_mode Application.compile_env(:hacker_news, :plug_init_mode, :compile)

      use Plug.Router, init_mode: @plug_init_mode

      defp render(conn, template, data) do
        [template, format] = :binary.split(template, ".")
        body = StoryView.render(template, format, data)

        conn
        |> resp(conn.status || 200, body)
        |> resp_content_type(format)
      end

      defp resp_content_type(conn, "json") do
        put_resp_content_type(conn, "application/json")
      end
    end
  end

  def view do
    quote do
      def render(template, format, data) do
        content = render_template(template, data)
        encode(content, format)
      end

      defp encode(content, "json"), do: Jason.encode_to_iodata!(content)
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
