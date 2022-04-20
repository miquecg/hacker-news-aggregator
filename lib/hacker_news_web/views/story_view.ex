defmodule HackerNewsWeb.StoryView do
  use HackerNewsWeb, :view

  defp render_template("collection", %{stories: stories} = data, conn) do
    %{
      items: stories,
      count: length(stories),
      meta: render_template("meta", data, conn)
    }
  end

  @template_meta %{
    page: nil,
    prev: nil,
    next: nil
  }

  defp render_template("meta", %{stories: []}, _conn), do: @template_meta

  defp render_template("meta", data, conn) do
    %{
      @template_meta
      | page: data.page,
        prev: cursor_previous(data, conn),
        next: cursor_next(data, conn)
    }
  end

  defp cursor_previous(%{prev: :end_of_table}, _conn), do: nil
  defp cursor_previous(data, conn), do: sign_url({data.page - 1, data.prev}, conn)

  defp cursor_next(%{next: :end_of_table}, _conn), do: nil
  defp cursor_next(data, conn), do: sign_url({data.page + 1, data.next}, conn)

  defp sign_url({_page, _cursor} = data, conn) do
    signed =
      Plug.Crypto.sign(
        conn.secret_key_base,
        "pages",
        data
      )

    path = ["#{conn.request_path}", "?page=", "#{signed}"]
    url = ["#{conn.scheme}", "://", "#{conn.host}", ":", "#{conn.port}", path]
    IO.iodata_to_binary(url)
  end
end
