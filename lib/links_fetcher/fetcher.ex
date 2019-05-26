defmodule LinksFetcher.Fetcher do
  require Logger
  use GenServer
  alias LinksFetcher.Fetched

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def start_supervised do
    DynamicSupervisor.start_child(LinksFetcher.DynamicSupervisor, {__MODULE__, fn -> nil end})
  end

  def fetch(fetcher, data) do
    GenServer.cast(fetcher, {:fetch, data})
  end

  def result(fetcher, timeout \\ 30000) do
    GenServer.call(fetcher, :result, timeout)
  end

  # Callbacks
  @impl true
  def init(data) do
    {:ok, data}
  end

  def fetch_links(url, depth \\ 1, statics \\ false, timeout \\ 10000) do
    base = get_base(url)
    # spawn process for caching of crawled urls
    {:ok, fetcher_checker} = Fetched.start_link()

    res =
      do_fetch(url, base, depth, statics, fetcher_checker, timeout)
      |> result(timeout)

    cleanup(fetcher_checker)
    res
  end

  def cleanup(fetched) do
    Process.exit(fetched, :normal)
  end

  @impl true
  def handle_cast({:fetch, {url, base, depth, statics, fetcher_checker, timeout}}, _data) do
    res = Fetched.url_fetched?(fetcher_checker, url)

    case res do
      true ->
        {:noreply, []}

      false ->
        if depth == 0 do
          {:noreply, []}
        else
          {:ok, links} = fetch_unfetched(url, fetcher_checker, statics, depth, base, timeout)
          {:noreply, links}
        end
    end
  end

  @impl true
  def handle_call(:result, _from, data) do
    {:reply, data, nil}
  end

  defp do_fetch(url, base, depth, statics, fetcher_checker, timeout) do
    {:ok, fetcher} = start_supervised()
    fetch(fetcher, {url, base, depth, statics, fetcher_checker, timeout})
    fetcher
  end

  defp fetch_unfetched(url, fetcher_checker, statics, depth, base, timeout) do
    Fetched.add_fetched(fetcher_checker, url)
    {:ok, links} = fetch_data(base, url, statics)

    if Enum.empty?(links) do
      {:ok, []}
    else
      # Here is the magic, spawn child process per link retrieved
      # this new process will crawl in the level inside

      # spawn crawlers
      newlinks =
        Enum.map(links, fn x ->
          do_fetch(base <> x, base, depth - 1, statics, fetcher_checker, timeout)
        end)
        # fetch results
        |> Enum.map(fn fetcher ->
          result(fetcher, timeout)
        end)
        # Reduce responses
        |> Enum.reduce(fn l1, l2 -> l1 ++ l2 end)

      {:ok, links ++ newlinks}
    end
  end

  defp get_base(url) do
    [_matched, base] = Regex.run(~r/(https?:\/\/[\w.]*)\/?/, url)
    base
  end

  defp fetch_data(base, url, statics) do
    Logger.debug("Fetching: #{url}")

    case :hackney.request(
           :get,
           url,
           [
             {"User-Agent",
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.3 Safari/605.1.15"}
           ],
           "",
           pool: :default,
           follow_redirect: true,
           max_redirect: 5,
           force_redirect: true
         ) do
      {:ok, _status, _headers, client} ->
        {:ok, body} = :hackney.body(client)
        data = get_links(base, body, statics)

        links =
          Enum.map(data, fn item -> Enum.at(item, -1) end)
          |> Enum.reduce([], fn x, accum -> reduce_links(x, accum) end)

        {:ok, links}

      {:error, _error} ->
        {:ok, []}
    end
  end

  defp get_links(base, body, statics) do
    if statics do
      {:ok, rgx} = Regex.compile("href=\"(#{base})?([/]{1}[\\w\\.-\\?\\&\\=/]*)\"")
      res = Regex.scan(rgx, body)
      Enum.filter(res, fn x -> Enum.at(x, -1) != "" end)
    else
      Regex.scan(~r/href="([\/]{1}[\w-\?\&\=\/]*)"/, body)
      {:ok, rgx} = Regex.compile("href=\"(#{base})?([/]{1}[\\w-\\?\\&\\=/]*)\"")
      res = Regex.scan(rgx, body)
      Enum.filter(res, fn x -> Enum.at(x, -1) != "" end)
    end
  end

  defp reduce_links(link, accum) do
    if Enum.member?(accum, link) do
      accum
    else
      accum ++ [link]
    end
  end
end
