defmodule HackerNews.Repo do
  @moduledoc """
  Access to data storage for Hacker News API.
  """

  use Agent

  @top_stories [
    %{
      by: "dhouston",
      descendants: 71,
      id: 8863,
      kids: [
        8952,
        9224,
        8917,
        8884,
        8887
      ],
      score: 111,
      time: 1_175_714_200,
      title: "My YC app: Dropbox - Throw away your USB drive",
      type: "story",
      url: "http://www.getdropbox.com/u/2/screencast.html"
    }
  ]

  def start_link(opts) do
    Agent.start_link(fn -> @top_stories end, opts)
  end

  def get_all(agent), do: Agent.get(agent, & &1)
end
