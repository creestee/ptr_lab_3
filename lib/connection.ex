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

  def handle_info({:tcp, socket, data}, state) do
    Logger.info("Received #{data}")

    [first_token | arguments] =
      String.trim(data)
      |> String.split(" ")

    case first_token do
      "create" ->
        Logger.debug("create command")

        [client_type | tail] = arguments
        [name | topic] = tail

        cond do
          client_type == "publisher" ->
            Publisher.start(name, topic)

          client_type == "subscriber" ->
            Subscriber.start(name, topic)

          true ->
            Logger.debug("UNKNOWN CLIENT TYPE")
            :gen_tcp.send(socket, "UNKNOWN CLIENT TYPE\n")
        end

      # :gen_tcp.send(socket, "#{arguments}\n")

      "quit" ->
        Logger.debug("some quit command")
        :gen_tcp.send(socket, "#{arguments}\n")

      _ ->
        Logger.debug("Unknown command: #{inspect(data)}")
        :gen_tcp.send(socket, "unknown command\n")
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
