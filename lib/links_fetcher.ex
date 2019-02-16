defmodule LinksFetcher do
  require Logger
  @moduledoc """
  Documentation for LinksFetcher.
  """
  @doc """
  Fetch Links.

  ## Examples

      iex> LinksFetcher.fetch_links("https://www.google.com", 1)
      {:ok, ["/preferences?hl=es", "/intl/es/ads/", "/intl/es/policies/privacy/", "/intl/es/policies/terms/"]}
  """
  def fetch_links(url, depth \\ 1, statics \\ false) do
    base = get_base(url)
    {:ok, fetcher_checker} = Task.start_link(fn -> fetched([]) end)
    parent = self()
    spawn(fn -> do_fetch(url, base, depth, fetcher_checker, statics, parent) end)
    receive do
      {:ok, links} ->
        {:ok, links}
    end
  end

  defp fetched(list) do
    receive do
      {:add, url} ->
        fetched([url | list])
      {:check, sender, url} ->
        send(sender, {:check, Enum.member?(list, url)})
    end
    fetched(list)
  end

  defp do_fetch(url, base, depth, fetcher_checker, statics, caller) do
    me = self()
    send(fetcher_checker, {:check, me, url})

    receive do
      {:check, true} ->
        send(caller, {:ok, []})
      {:check, false} ->
        if depth == 0 do
          send(caller, {:ok, []})
        else
          send(fetcher_checker, {:add, url})
          {:ok, links} = fetch_data(url, statics)
          if Enum.empty?(links) do
            send(caller, {:ok, []})
          else
            {:ok, newlinks} = Enum.map(links, fn x ->
                spawn(fn ->
                  do_fetch(base <> x, base, depth - 1, fetcher_checker, statics, me)
                end)
              end) |>
              Enum.map(fn _x ->
                receive do
                  {:ok, links} -> {:ok, links}
                end
              end) |>
              Enum.reduce(fn {:ok, links1}, {:ok, links2} -> {:ok, links1 ++ links2} end)

            send(caller, {:ok, links ++ newlinks})
          end
        end
    end
  end

  defp get_base(url) do
    [_matched, base] = Regex.run(~r/(https?:\/\/[\w.]*)\/?/, url)
    base
  end

  defp fetch_data(url, statics) do
    Logger.debug "Fetching: #{url}"
    case :hackney.request(
      :get, url, [
        pool: :default,
        follow_redirect: true,
        max_redirect: 5,
        force_redirect: true
      ]
    ) do
      {:ok, _status, _headers, client} ->
        {:ok, body} = :hackney.body(client)
        data = get_links(body, statics)
        links = Enum.map(data, fn [_head | tail] -> tail end)
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
