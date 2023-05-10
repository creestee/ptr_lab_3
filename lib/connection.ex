defmodule Connection do
  require Logger
  use GenServer

  def start(port) do
    GenServer.start(__MODULE__, %{socket: nil, port: port, client_type: {nil, nil}},
      name: :"connection_#{port}"
    )
  end

  @impl true
  def init(%{socket: _, port: port}) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: true])
    send(self(), :accept)

    Logger.info("Accepting connection on port #{port}...")
    {:ok, %{socket: socket, port: port}}
  end

  @impl true
  def handle_info(:accept, %{socket: socket} = state) do
    {:ok, _} = :gen_tcp.accept(socket)
    Logger.info("Client connected")
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, socket, data_received}, state) do
    [first_token | data] =
      String.trim(data_received)
      |> String.split(" ")

    case first_token do
      "new" ->
        handle_new(data, state)

      "send" ->
        handle_send(socket, data, state)

      "subscribe" ->
        handle_subscribe(socket, data, state)

      "quit" ->
        handle_quit()

      _ ->
        handle_unknown(socket, data_received, state)
    end
  end

  @impl true
  def handle_info({:tcp_closed, socket}, state) do
    Logger.info("Connection closed: #{inspect(socket)}")
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:tcp_error, socket}, state) do
    Logger.error("Connection closed: #{inspect(socket)}")
    {:stop, :normal, state}
  end

  defp handle_new_actor("publisher") do
    {:ok, publisher_pid} = Publisher.start()
    {:publisher, publisher_pid}
  end

  defp handle_new_actor("subscriber") do
    {:ok, subscriber_pid} = Subscriber.start()
    {:subscriber, subscriber_pid}
  end

  defp handle_new(data, state) do
    client_type = Enum.join(data)
    {client, client_pid} = handle_new_actor(client_type)
    {:noreply, Map.put(state, :client_type, {client, client_pid})}
  end

  defp handle_send(_socket, data, state = %{client_type: {:publisher, pid}}) do
    Publisher.send_to_topic(pid, data)
    {:noreply, state}
  end

  defp handle_send(socket, _data, state) do
    Logger.info("NOT A PUBLISHER")
    :gen_tcp.send(socket, "YOU ARE NOT A PUBLISHER\r\n")
    {:noreply, state}
  end

  defp handle_subscribe(_socket, data, state = %{client_type: {:subscriber, pid}}) do
    # TODO: add condition to check if the topic exists
    Subscriber.subscribe_new_topic(pid, data)
    {:noreply, state}
  end

  defp handle_subscribe(socket, _data, state) do
    Logger.info("NOT A SUBSCRIBER")
    :gen_tcp.send(socket, "YOU ARE NOT A SUBSCRIBER\r\n")
    {:noreply, state}
  end

  defp handle_quit() do
    Logger.debug("QUIT!!!")
    Process.exit(self(), :kill)
  end

  defp handle_unknown(socket, data, state) do
    Logger.debug("Unknown command: #{inspect(data)}")
    :gen_tcp.send(socket, "unknown command\r\n")
    {:noreply, state}
  end
end
