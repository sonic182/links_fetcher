defmodule LinksFetcher do
  use Application

  require Logger

  alias LinksFetcher.Fetcher

  @moduledoc """
  Documentation for LinksFetcher.
  """
  @doc """
  Fetch Links.

  ## Examples

      iex> LinksFetcher.fetch_links("https://www.mogollon.com.ve/es/", 1)
      ["/es/", "/es/courses/"]
  """
  def fetch_links(url, depth \\ 1, statics \\ false) do
    Fetcher.fetch_links(url, depth, statics)
  end

  @spec start(any(), any()) :: any()
  def start(_type, _args) do
    LinksFetcher.DynamicSupervisor.start_link(name: LinksFetcher.DynamicSupervisor)
  end
end
