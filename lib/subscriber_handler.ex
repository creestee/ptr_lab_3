defmodule SubscriberHandler do
  require Logger
  use GenServer

  @impl true
  def init(args) do
    {:ok, args}
  end

  def start() do
    GenServer.start_link(__MODULE__, %{}, name: :sub_handler)
  end

  @impl true
  def handle_cast({:new_topic, topic_name}, topics_map) do
    {:noreply, Map.put(topics_map, topic_name, [])}
  end

  @impl true
  def handle_cast({:update_topic_pids, topic, pid}, state) do
    case subscribed?(state, topic, pid) do
      true ->
        Logger.info("Subscriber [#{inspect(pid)}] is already subscribed to topic [#{topic}]")
        {:noreply, state}

      false ->
        new_state =
          state
          |> Map.update(topic, [], fn current_value -> [pid | current_value] end)

        Logger.info("Subscriber [#{inspect pid}] subscribed to topic [#{topic}]")

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:unsubscribe, topic, pid}, state) do
    case Map.get(state, topic) do
      # Topic doesn't exist, return the original map
      nil ->
        {:noreply, state}

      subscribers ->
        updated_subscribers = List.delete(subscribers, pid)
        {:noreply, Map.put(state, topic, updated_subscribers)}
    end
  end

  @impl true
  def handle_call(:get_topics, _from, state) do
    {:reply, state, state}
  end

  def new_topic(topic_name) do
    GenServer.cast(:sub_handler, {:new_topic, topic_name})
  end

  def get_topics() do
    GenServer.call(:sub_handler, :get_topics)
  end

  def update_topic_pids(topic, pid) do
    GenServer.cast(:sub_handler, {:update_topic_pids, topic, pid})
  end

  def unsubscribe_from_topic(topic, pid) do
    GenServer.cast(:sub_handler, {:unsubscribe, topic, pid})
  end

  def subscribed?(map, topic, pid) do
    map
    |> Map.get(topic)
    |> Enum.member?(pid)
  end
end
