defmodule Publisher do
  require Logger
  use GenServer

  @impl true
  def init(_init_args) do
    {:ok, nil}
  end

  def start() do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    Logger.info("Starting new Publisher")
    {:ok, pid}
  end

  @impl true
  def handle_cast({:send_to_topic, data}, state) do
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

  def send_to_topic(publisher_pid, message) do
    GenServer.cast(publisher_pid, {:send_to_topic, message})
  end
end
