defmodule HackerNews do
  @moduledoc """
  Service layer to encapsulate business logic.
  """

  alias HackerNews.Repo
  alias HackerNewsApi.{Client, Client.Response, Resource}

  def get_stories, do: Repo.get_all(:stories)

  @type option ::
          {:max_items, pos_integer()}
          | {:chunk_size, pos_integer()}
  @type opts :: [option]

  @defaults [max_items: 50, chunk_size: 10]

  @client_opts [{:decode, {"application/json", &Jason.decode/1}}]

  @spec update_stories(opts) :: :ok
  def update_stories(opts) do
    opts = Keyword.merge(@defaults, opts)
    {:ok, resource} = Resource.TopStories.new()

    with {:ok, %Response{status: 200, body: ids}} <- Client.request(resource, @client_opts),
         %{stories: _, errors: _} <- request_many(ids, opts) do
      :ok
    end
  end

  @typep ids :: [pos_integer()]
  @typep story :: map()
  @typep error :: {Resource.Story.t(), any()}
  @typep fetch_results :: %{stories: [story], errors: [error]}

  @spec request_many(ids, opts) :: fetch_results
  defp request_many(ids, opts) when is_list(ids) do
    resources =
      ids
      |> Stream.take(opts[:max_items])
      |> Stream.map(fn id ->
        {:ok, resource} = Resource.Story.new(item: id)
        resource
      end)

    results = request_resources(resources, opts[:chunk_size])
    acc = %{stories: [], errors: []}

    zip_with(results, resources, acc)
  end

  defp request_resources(resources, chunk_size) do
    resources
    |> Stream.chunk_every(chunk_size)
    |> Stream.flat_map(&request_resources/1)
  end

  defp request_resources(resources) do
    Task.Supervisor.async_stream(
      HackerNewsApi.TaskSupervisor,
      resources,
      Client,
      :request,
      [@client_opts],
      max_concurrency: length(resources),
      on_timeout: :kill_task,
      shutdown: :brutal_kill
    )
    |> Stream.map(fn
      {:ok, result} -> process_result(result)
      {:exit, :timeout} -> {:error, :timeout}
    end)
  end

  defp process_result({:ok, %Response{status: 200} = response}), do: {:ok, response.body}

  defp process_result({:ok, %Response{} = response}), do: {:error, response}

  defp process_result({:error, _} = error), do: error

  defp zip_with(results, resources, acc) do
    results
    |> Stream.zip_with(resources, fn
      {:ok, %{"id" => _} = story}, _ -> story
      {:error, error}, resource -> {resource, error}
    end)
    |> Enum.reduce(acc, &reducer/2)
  end

  @spec reducer(story, fetch_results) :: fetch_results
  defp reducer(%{} = story, acc), do: put(acc, :stories, story)

  @spec reducer(error, fetch_results) :: fetch_results
  defp reducer({%Resource.Story{}, _} = error, acc), do: put(acc, :errors, error)

  defp put(acc, key, elem) do
    {nil, acc} = get_and_update_in(acc, [key], &{nil, [elem | &1]})
    acc
  end
end
