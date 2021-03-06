defmodule HackerNews do
  @moduledoc """
  Service layer to encapsulate business logic.
  """

  @dialyzer {:no_contracts, reducer: 2}

  alias HackerNews.Repo
  alias HackerNewsApi.{Client, Client.Response, Error.ResourceError, Resource}

  @typep story :: map()
  @typep cursor :: Repo.cursor()

  @type paginated :: %{
          required(:stories) => [story],
          optional(:prev) => cursor,
          optional(:next) => cursor
        }

  @spec get_stories :: paginated
  def get_stories, do: all(limit: 10)

  @spec get_stories(cursor) :: paginated
  def get_stories(cursor), do: all(cursor: cursor)

  defp all(opts) do
    case Repo.all(opts) do
      [] ->
        %{stories: []}

      {stories, prev, next} ->
        %{stories: stories, prev: prev, next: next}
    end
  end

  @spec get_by(pos_integer()) :: story | nil
  def get_by(id) do
    case Repo.get(id) do
      [story] -> story
      [] -> nil
    end
  end

  @type fetch_option ::
          {:max_items, pos_integer()}
          | {:chunk_size, pos_integer()}
  @type fetch_opts :: [fetch_option]

  @type error :: ResourceError.t()
  @type fetch_result :: %{stories: [story], errors: [error]}

  @defaults [max_items: 50, chunk_size: 10]
  @client_opts [{:decode, {"application/json", &Jason.decode/1}}]

  @spec fetch_top(fetch_opts) :: fetch_result
  def fetch_top(opts \\ []) do
    opts = Keyword.merge(@defaults, opts)
    {:ok, resource} = Resource.TopStories.new()

    case Client.request(resource, @client_opts) do
      {:ok, %Response{status: 200, body: ids}} ->
        request_many(ids, opts)

      {:error, error} ->
        %{stories: [], errors: [error]}
    end
  end

  @typep ids :: [pos_integer()]

  @spec request_many(ids, fetch_opts) :: fetch_result
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
      {:ok, %{"id" => id} = story}, _ when is_integer(id) ->
        story

      {:error, %ResourceError{} = error}, _ ->
        error

      {:error, %Response{} = response}, resource ->
        build_error(:invalid_response, resource, response)

      {:error, reason}, resource ->
        build_error(reason, resource)
    end)
    |> Enum.reduce(acc, &reducer/2)
  end

  defp build_error(reason, resource, response \\ nil) when is_atom(reason) do
    %ResourceError{
      reason: reason,
      resource: resource,
      response: response
    }
  end

  @spec reducer(story | error, fetch_result) :: fetch_result
  defp reducer(result, acc)

  defp reducer(%ResourceError{} = error, acc), do: put(acc, :errors, error)
  defp reducer(%{"type" => "story"} = story, acc), do: put(acc, :stories, story)
  defp reducer(%{"type" => "job"}, acc), do: acc

  defp put(acc, key, elem) do
    {nil, acc} = get_and_update_in(acc, [key], &{nil, [elem | &1]})
    acc
  end
end
