defmodule Connection do
  require Logger
  use GenServer

  def start(port) do
    GenServer.start(__MODULE__, %{socket: nil, port: port, client_type: nil}, name: :connection)
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
    Logger.info("Received #{data_received}")

    [first_token | data] =
      String.trim(data_received)
      |> String.split(" ")

    Logger.debug(data)
    Logger.debug(first_token)

    case first_token do
      "new" ->
        client_type =
          data
          |> Enum.join("")

        {role, role_pid} = handle_new_actor(client_type)

        {:noreply, Map.put(state, :client_type, {role, role_pid})}

      "send" ->
        {role, _} = Map.get(state, :client_type)

        if role !== :publisher do
          Logger.info("NOT A PUBLISHER")
          :gen_tcp.send(socket, "YOU ARE NOT A PUBLISHER\r\n")
          {:noreply, state}
        else
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

          {:noreply, state}
        end

      "subscribe" ->
        Logger.debug("-- CONSUMING --")

        topic =
          data
          |> Enum.join("")
          |> String.to_atom()

        topics_map = SubscriberHandler.get_topics()

        if !Map.has_key?(topics_map, topic) do
          {:ok, pid} = Subscriber.start()
          SubscriberHandler.new_topic(topic)
          SubscriberHandler.update_topic_pids(topic, pid)
        end

        {:noreply, state}

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

  def show_state() do
    GenServer.call(:connection, :show_state)
  end
end
