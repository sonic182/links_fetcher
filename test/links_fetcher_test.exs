defmodule LinksFetcherTest do
  use ExUnit.Case
  doctest LinksFetcher

  test "minimal http sample" do
    {:ok, _status, _respheaders, client} = :hackney.request(
      :get,
      "https://ipinfo.io/ip",
      [pool: :default, follow_redirect: true, max_redirect: 5, force_redirect: true]
    )
    {:ok, body} = :hackney.body(client)
    assert Regex.match?(~r/^[\d.]*\n$/, body)
  end

  test "fetch links" do
    {:ok, links} = LinksFetcher.fetch_links("https://www.inmoduran.net/es/", 100)
    all_are_links = Enum.map(links, fn x -> Regex.match?(~r/^[\/]{1}\S*$/, x) end) |>
      Enum.reduce(true, fn x, y -> x and y end)
    assert all_are_links
  end
end
