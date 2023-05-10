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
        client_type =
          data
          |> Enum.join("")

        {client, client_pid} = handle_new_actor(client_type)

        {:noreply, Map.put(state, :client_type, {client, client_pid})}

      "send" ->
        {client, pid} = Map.get(state, :client_type)

        cond do
          client !== :publisher ->
            Logger.info("NOT A PUBLISHER")
            :gen_tcp.send(socket, "YOU ARE NOT A PUBLISHER\r\n")
            {:noreply, state}

          true ->
            Publisher.send_to_topic(pid, data)
            {:noreply, state}
        end

      "subscribe" ->
        {client, pid} = Map.get(state, :client_type)

        cond do
          client !== :subscriber ->
            Logger.info("NOT A SUBSCRIBER")
            :gen_tcp.send(socket, "YOU ARE NOT A SUBSCRIBER\r\n")
            {:noreply, state}

          # TODO: add condition to check if the topic exists

          true ->
            Subscriber.subscribe_new_topic(pid, data)
            {:noreply, state}
        end

      "quit" ->
        Logger.debug("some quit command")
        :gen_tcp.send(socket, "#{data_received}\r\n")
        Process.exit(self(), :kill)

      _ ->
        Logger.debug("Unknown command: #{inspect(data)}")
        :gen_tcp.send(socket, "unknown command\r\n")
        {:noreply, state}
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

  @impl true
  def handle_call(:show_state, _from, state) do
    {:reply, state, state}
  end

  defp handle_new_actor("publisher") do
    {:ok, publisher_pid} = Publisher.start()
    {:publisher, publisher_pid}
  end

  defp handle_new_actor("subscriber") do
    {:ok, subscriber_pid} = Subscriber.start()
    {:subscriber, subscriber_pid}
  end

  def show_state(port) do
    GenServer.call(:"connection_#{port}", :show_state)
  end
end
