defmodule Subscriber do
  require Logger
  use GenServer

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  def start() do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    Logger.info("Starting a new Subscriber with pid [#{inspect(pid)}]")
    {:ok, pid}
  end

  @impl true
  def handle_cast({:consume, message}, state) do
    Logger.info("Subscriber [#{inspect(self())}] consumed this message : #{message}")
    :gen_tcp.send(state.socket, "-----------------------------------\r\n")
    :gen_tcp.send(state.socket, "Message consumed : #{message}\r\n");
    :gen_tcp.send(state.socket, "-----------------------------------\r\n")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:subscribe_new_topic, data}, state) do
    topic =
      data
      |> Enum.join("")
      |> String.to_atom()

    case Process.whereis(:"#{topic}") do
      nil ->
        Logger.debug("Topic [#{topic}] does not exist")
        :gen_tcp.send(state.socket, "[WARNING] Topic [#{topic}] does not exist!\r\n");
        {:noreply, state}

      _ ->
        topics_map = SubscriberHandler.get_topics()

        if !Map.has_key?(topics_map, topic), do: SubscriberHandler.new_topic(topic)

        SubscriberHandler.update_topic_pids(topic, self())

        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:unsubscribe, data}, state) do
    topic =
      data
      |> Enum.join("")
      |> String.to_atom()

    case Process.whereis(:"#{topic}") do
      nil ->
        Logger.debug("Topic [#{topic}] does not exist")
        :gen_tcp.send(state.socket, "[WARNING] Topic [#{topic}] does not exist!\r\n");
        {:noreply, state}

      _ ->
        SubscriberHandler.unsubscribe_from_topic(topic, self())

        Logger.info("Subscriber [#{inspect(self())}] unsubscribed to topic [#{topic}]")
        Logger.info("#{inspect(SubscriberHandler.get_topics())}")
        {:noreply, state}
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:get_connection_pid, socket}, state) do
    {:noreply, Map.put(state, :socket, socket)}
  end

  def consume_from_topic(subscriber_pid, message) do
    GenServer.cast(subscriber_pid, {:consume, message})
  end

  def subscribe_new_topic(subscriber_pid, data) do
    GenServer.cast(subscriber_pid, {:subscribe_new_topic, data})
  end

  def unsubscribe(subscriber_pid, data) do
    GenServer.cast(subscriber_pid, {:unsubscribe, data})
  end
end
