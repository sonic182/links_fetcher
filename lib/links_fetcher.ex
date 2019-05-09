defmodule LinksFetcher do
  require Logger

  @moduledoc """
  Documentation for LinksFetcher.
  """
  @doc """
  Fetch Links.

  ## Examples

      iex> LinksFetcher.fetch_links("https://www.mogollon.com.ve/es/", 1)
      {:ok, ["/es/", "/es/courses/"]}
  """
  def fetch_links(url, depth \\ 1, statics \\ false) do
    base = get_base(url)
    # spawn process for caching of crawled urls
    {:ok, fetcher_checker} = Task.start_link(fn -> fetched(MapSet.new()) end)
    parent = self()

    # spawn recursive fetcher of links
    spawn(fn -> do_fetch(url, base, depth, fetcher_checker, statics, parent) end)

    receive do
      {:ok, links} ->
        Process.exit(fetcher_checker, :normal)
        {:ok, links}
    end
  end

  defp fetched(set) do
    receive do
      {:add, url} ->
        fetched(set |> MapSet.put(url))

      {:check, sender, url} ->
        send(sender, {:check, MapSet.member?(set, url)})
    end

    fetched(set)
  end

  defp do_fetch(url, base, depth, fetcher_checker, statics, caller) do
    me = self()
    send(fetcher_checker, {:check, me, url})
    checked_url(caller, fetcher_checker, depth, url, statics, me, base)
  end

  defp checked_url(caller, fetcher_checker, depth, url, statics, me, base) do
    receive do
      {:check, true} ->
        send(caller, {:ok, []})

      {:check, false} ->
        if depth == 0 do
          send(caller, {:ok, []})
        else
          fetch_unfetched(url, fetcher_checker, url, statics, caller, depth, me, base)
        end
    end
  end

  defp fetch_unfetched(url, fetcher_checker, url, statics, caller, depth, me, base) do
    send(fetcher_checker, {:add, url})
    {:ok, links} = fetch_data(url, statics)

    if Enum.empty?(links) do
      send(caller, {:ok, []})
    else
      # Here is the magic, spawn child process per link retrieved
      # this new process will crawl in the level inside

      # spawn crawlers
      {:ok, newlinks} =
        Enum.map(links, fn x ->
          spawn(fn ->
            do_fetch(base <> x, base, depth - 1, fetcher_checker, statics, me)
          end)
        end)
        # receive from crawlers
        |> Enum.map(fn _x ->
          receive do
            {:ok, links} -> {:ok, links}
          end
        end)
        # Reduce responses
        |> Enum.reduce(fn {:ok, links1}, {:ok, links2} -> {:ok, links1 ++ links2} end)

      send(caller, {:ok, links ++ newlinks})
    end
  end

  defp get_base(url) do
    [_matched, base] = Regex.run(~r/(https?:\/\/[\w.]*)\/?/, url)
    base
  end

  defp fetch_data(url, statics) do
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
        data = get_links(body, statics)

        links =
          Enum.map(data, fn [_head | tail] -> tail end)
          |> Enum.map(fn [item] -> item end)
          |> Enum.reduce([], fn x, accum -> reduce_links(x, accum) end)

        {:ok, links}

      {:error, _error} ->
        {:ok, []}
    end
  end

  defp get_links(body, statics) do
    if statics do
      Regex.scan(~r/href="([\/]{1}[\w\.-\?\&\=\/]*)"/, body)
    else
      Regex.scan(~r/href="([\/]{1}[\w-\?\&\=\/]*)"/, body)
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
