defmodule Subscriber do
  require Logger
  use GenServer

  @impl true
  def init(_args) do
    {:ok, nil}
  end

  def start() do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    Logger.info("Starting a new Subscriber with pid [#{inspect(pid)}]")
    {:ok, pid}
  end

  @impl true
  def handle_cast({:consume, message}, state) do
    Logger.info("Subscriber [#{inspect(self())}] consumed this message : #{message}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:subscribe_new_topic, data}, state) do
    topic =
      data
      |> Enum.join("")
      |> String.to_atom()

    topics_map = SubscriberHandler.get_topics()

    if !Map.has_key?(topics_map, topic) do
      SubscriberHandler.new_topic(topic)
    end

    SubscriberHandler.update_topic_pids(topic, self())

    Logger.info("Subscriber [#{inspect(self())}] subscribed to topic [#{topic}]")
    Logger.info("#{inspect(SubscriberHandler.get_topics())}")

    {:noreply, state}
  end

  def consume_from_topic(subscriber_pid, message) do
    GenServer.cast(subscriber_pid, {:consume, message})
  end

  def subscribe_new_topic(subscriber_pid, data) do
    GenServer.cast(subscriber_pid, {:subscribe_new_topic, data})
  end
end
