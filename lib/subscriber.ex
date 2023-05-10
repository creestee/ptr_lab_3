defmodule Subscriber do
  require Logger
  use GenServer

  @impl true
  def init(_args) do
    {:ok, nil}
  end

  def start() do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    Logger.info("Starting a new Subscriber with pid [#{inspect pid}]")
    {:ok, pid}
  end

  @impl true
  def handle_cast({:consume, message}, state) do
    Logger.info("Subscriber [#{inspect self()}] consumed this message : #{message}")
    {:noreply, state}
  end

  def consume_from_topic(subscriber_pid, message) do
    GenServer.cast(subscriber_pid, {:consume, message})
  end
end
