# LinksFetcher

Sample links fetcher.

It crawls given url in parallel spawning processes and using [hackney](https://github.com/benoitc/hackney).

At this time just crawls relative paths in given url.

* Docs: [https://hexdocs.pm/links_fetcher](https://hexdocs.pm/links_fetcher)
* Hex: [https://hex.pm/packages/links_fetcher](https://hex.pm/packages/links_fetcher)

## Installation

The package can be installed by adding `links_fetcher` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:links_fetcher, "~> 0.2.0"}
  ]
end
```

## Example

```elixir
iex> LinksFetcher.fetch_links("https://www.google.com", 1)
  ["/intl/es_es/policies/privacy/?fg=1", "/intl/es_es/policies/terms/?fg=1", "/preferences?hl=es", "/calendar?tab=wc"]
```
