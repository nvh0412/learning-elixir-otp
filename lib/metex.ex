defmodule Metex do
  def temperature_of(cities) do
    coordinate_pid = spawn(Metex.Coordinator, :loop, [[], Enum.count(cities)])

    cities |> Enum.each(fn city ->
      worker_id = spawn(Metex.Worker, :loop, [])
      send worker_id, { coordinate_pid, city }
    end)
  end

  defmodule Ping do
    def loop do
      receive do
        {sender_pid, "ping"} ->
          IO.puts "ping"
          send sender_pid, { self, "pong" }
          loop()
        _ -> loop()
      end
    end
  end

  defmodule Pong do
    def loop do
      receive do
        {sender_pid, "pong"} ->
          IO.puts "pong"
          send sender_pid, { self, "ping" }
          loop()
        _ -> loop()
      end
    end
  end
end
