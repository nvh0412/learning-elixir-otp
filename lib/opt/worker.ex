defmodule Metex.OTP.Worker do
  use GenServer

  @name MW

  ## client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: MW])
  end

  def get_temporary(pid, location) do
    GenServer.call(pid, { :location, location })
  end

  def get_stats do
    GenServer.call(@name, :get_stats)
  end

  def reset_stats do
    GenServer.cast(@name, :restart_stats)
  end

  def stop do
    GenServer.cast(@name, :stop)
  end

  ## server API
  def init(:ok) do
    {:ok, %{}}
  end

  def terminate(reason, stats) do
    IO.puts "Server terminate because of #{reason}"
    IO.inspect stats

    :ok
  end

  def handle_cast(:restart_stats, _stats) do
    {:noreply, %{}}
  end

  def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end

  def handle_call(:get_stats, _from, stats) do
    {:reply, stats, stats}
  end

  def handle_call({:location, location }, _from, stats) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_stats = update_stats(stats, location)
        {:reply, "#{temp}*C", new_stats}
      _ ->
        {:reply, :error, stats}
    end
  end

  ## Helper function
  def update_stats(old_stats, location) do
    case Map.has_key?(old_stats, location) do
      true ->
        Map.update!(old_stats, location, &(&1 + 1))
      false ->
        Map.put_new(old_stats, location, 1)
    end
  end

  def temperature_of(location) do
    url_for(location) |> HTTPoison.get |> parse_response
  end

  defp url_for(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey()}"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode! |> compute_temperature
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp apikey do
    "206fdddf5212cf09a70632b49691cf91"
  end
end
