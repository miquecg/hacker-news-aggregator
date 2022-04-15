defmodule HackerNewsWeb do
  @moduledoc """
  The entrypoint for defining the web interface.
  """

  alias HackerNewsWeb.StoryView

  def router do
    quote do
      @plug_init_mode Application.compile_env(:hacker_news, [:web, :plug_init_mode], :compile)

      use Plug.Router, init_mode: @plug_init_mode

      @impl true
      def init([]) do
        config = Application.fetch_env!(:hacker_news, :web)
        secret = Keyword.fetch!(config, :secret_key_base)
        [secret: secret]
      end

      @impl true
      def call(conn, opts) do
        conn = put_private(conn, :view, StoryView)
        conn = %{conn | secret_key_base: opts[:secret]}
        super(conn, opts)
      end

      defp render(conn, template) do
        [template, format] = :binary.split(template, ".")
        module = conn.private.view
        body = module.render(template, format, conn)

        conn
        |> resp(conn.status || 200, body)
        |> resp_content_type(format)
      end

      defp resp_content_type(conn, "json") do
        put_resp_content_type(conn, "application/json")
      end

      defp put_view(conn, module), do: put_private(conn, :view, module)
    end
  end

  def view do
    quote do
      def render(template, format, conn) do
        content = render_template(template, conn.assigns, conn)
        encode(content, format)
      end

      defp encode(content, "json"), do: Jason.encode_to_iodata!(content)
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
