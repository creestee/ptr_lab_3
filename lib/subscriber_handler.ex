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
    new_state =
      state
      |> Map.update(topic, [], fn current_value -> [pid | current_value] end)

    {:noreply, new_state}
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
end
