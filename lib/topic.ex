defmodule Topic do
  require Logger
  use GenServer

  @impl true
  def init(_args) do
    {:ok, nil}
  end

  def start(name) do
    Logger.info("A new topic #{name} was created")
    GenServer.start_link(__MODULE__, :ok, name: String.to_atom(name))
  end

  @impl true
  def handle_call({:send, message, topic}, _from, state) do
    Enum.map(get_pids_by_topic(SubscriberHandler.get_topics(), :"#{topic}"), fn pid -> Subscriber.consume_from_topic(pid, message) end)
    # Logger.info(message)
    {:reply, :ok, state}
  end

  def send_message(message, topic) do
    :ok = GenServer.call(:"#{topic}", {:send, message, topic})
  end

  def get_pids_by_topic(map, topic_name) do
    case Map.fetch(map, topic_name) do
      {:ok, pids} -> pids
      :error -> []
    end
  end
end
