defmodule Connection do
  require Logger
  use GenServer

  def start(port) do
    GenServer.start(__MODULE__, %{socket: nil, port: port})
  end

  def init(%{socket: _, port: port}) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: true])
    send(self(), :accept)

    Logger.info("Accepting connection on port #{port}...")
    {:ok, %{socket: socket, port: port}}
  end

  def handle_info(:accept, %{socket: socket} = state) do
    {:ok, _} = :gen_tcp.accept(socket)
    Logger.info("Client connected")
    {:noreply, state}
  end

  def handle_info({:tcp, socket, data_received}, state) do
    Logger.info("Received #{data_received}")

    [first_token | data] =
      String.trim(data_received)
      |> String.split(" ")

    Logger.info(data)

    case first_token do
      "send" ->
        Logger.debug("-- TRYING TO SEND A MESSAGE --")

        [topic, message] =
          data
          |> Enum.join("")
          |> String.split("%")

        cond do
          is_nil(Process.whereis(:"#{topic}")) ->
            Topic.start(topic)
            Topic.send_message(message, topic)

          true ->
            Topic.send_message(message, topic)
        end

      "subscribe" ->
        Logger.debug("-- CONSUMING --")

        topic =
          data
          |> Enum.join("")
          |> String.to_atom()

        topics_map = SubscriberHandler.get_topics()

        if !Map.has_key?(topics_map, topic),
          do: SubscriberHandler.new_topic(topic)

        {:ok, pid} = Subscriber.start(topic)

        SubscriberHandler.update_topic_pids(topic, pid)

      "quit" ->
        Logger.debug("some quit command")
        :gen_tcp.send(socket, "#{data_received}\r\n")
        Process.exit(self(), :kill)

      _ ->
        Logger.debug("Unknown command: #{inspect(data)}")
        :gen_tcp.send(socket, "unknown command\r\n")
    end

    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    Logger.info("Connection closed: #{inspect(socket)}")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, socket}, state) do
    Logger.error("Connection closed: #{inspect(socket)}")
    {:stop, :normal, state}
  end
end
