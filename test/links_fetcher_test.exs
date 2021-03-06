defmodule LinksFetcherTest do
  use ExUnit.Case
  doctest LinksFetcher

  test "minimal http call sample" do
    {:ok, _status, _respheaders, client} =
      :hackney.request(
        :get,
        "https://ipinfo.io/ip",
        pool: :default,
        follow_redirect: true,
        max_redirect: 5,
        force_redirect: true
      )

    {:ok, body} = :hackney.body(client)
    assert Regex.match?(~r/^[\d.]*\n$/, body)
  end

  test "fetch links" do
    links = LinksFetcher.fetch_links("https://www.google.es", 3)

    all_are_links =
      Enum.map(links, fn x -> Regex.match?(~r/^([\/]{1}[\w-\.\?\&\=\/]*)$/, x) end)
      |> Enum.reduce(true, fn x, y -> x and y end)

    assert all_are_links
  end
end
