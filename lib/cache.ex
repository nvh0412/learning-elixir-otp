defmodule Metex.Cache do
  use GenServer

  @name MC

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: MC])
  end

  def write(key, value) do
    GenServer.call(@name, { :write, key, value })
  end

  def read(key) do
    GenServer.call(@name, { :read, key })
  end

  def delete(key) do
    GenServer.call(@name, { :delete, key })
  end

  def clear do
    GenServer.cast(@name, :clear)
  end

  def exist?(key) do
    GenServer.call(@name, { :exist, key })
  end

  # Server API
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({ :write, key, value }, _from, stats) do
    new_stats = update_stats(stats, key, value)
    {:reply, :ok, new_stats}
  end

  def handle_call({ :exist, key }, _from, stats) do
    {:reply, Map.has_key?(stats, key), stats}
  end

  def handle_call({ :read, key }, _from, stats) do
    {:reply, Map.get(stats, key), stats}
  end

  def handle_call({ :delete, key }, _from, stats) do
    new_stats = Map.delete(stats, key)
    {:reply, new_stats, new_stats}
  end

  def handle_cast(:clear, _stats) do
    {:noreply, %{}}
  end

  # Helper methods
  def update_stats(old_stats, key, value) do
    case Map.has_key?(old_stats, key) do
      true ->
        Map.update!(old_stats, key, &(&1 = value))
      false ->
        Map.put_new(old_stats, key, value)
    end
  end
end
