# LinksFetcher

Sample links fetcher.

It crawls given url in parallel spawning processes and using [hackney](https://github.com/benoitc/hackney).

* Docs: [https://hexdocs.pm/links_fetcher](https://hexdocs.pm/links_fetcher)
* Hex: [https://hex.pm/packages/links_fetcher](https://hex.pm/packages/links_fetcher)

## Installation

The package can be installed by adding `links_fetcher` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:links_fetcher, "~> 0.1.1"}
  ]
end
```

## Example

```elixir
iex> LinksFetcher.fetch_links("https://www.google.com", 1)
{:ok, ["/preferences?hl=es", "/intl/es/ads/", "/intl/es/policies/privacy/", "/intl/es/policies/terms/"]}
```
