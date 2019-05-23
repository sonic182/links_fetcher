defmodule LinksFetcher.Fetched do
  use GenServer

  # client
  def start_link() do
    GenServer.start_link(__MODULE__, MapSet.new())
  end

  def url_fetched?(pid, url) do
    GenServer.call(pid, {:check, url})
  end

  def add_fetched(pid, url) do
    GenServer.cast(pid, {:add, url})
  end

  # Callbacks
  @impl true
  def init(set) do
    {:ok, set}
  end

  @impl true
  def handle_call({:check, url}, _from, set) do
    {:reply, MapSet.member?(set, url), set}
  end

  @impl true
  def handle_cast({:add, url}, set) do
    {:noreply, MapSet.put(set, url)}
  end
end
