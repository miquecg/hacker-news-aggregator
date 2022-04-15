defmodule HackerNewsWeb.StoryView do
  use HackerNewsWeb, :view

  defp render_template("collection", %{stories: stories} = data, conn) do
    total = length(stories)

    %{
      items: stories,
      total: total,
      meta: render_template("meta", data, conn)
    }
  end

  @template_meta for key <- [:page, :next, :prev], into: %{}, do: {key, nil}

  defp render_template("meta", %{cursor: cursor}, conn) do
    %{@template_meta | page: 1, next: next_page(conn, {2, cursor})}
  end

  defp render_template("meta", %{stories: []}, _conn), do: @template_meta
  defp render_template("meta", %{stories: _}, _conn), do: %{@template_meta | page: 1}

  defp next_page(conn, {_number, _cursor} = data) do
    signed =
      Plug.Crypto.sign(
        conn.secret_key_base,
        "next-page",
        data,
        max_age: 300
      )

    path = ["#{conn.request_path}", "?page=", "#{signed}"]
    url = ["#{conn.scheme}", "://", "#{conn.host}", ":", "#{conn.port}", path]
    IO.iodata_to_binary(url)
  end
end
