defmodule Subscriber do
  require Logger
  use GenServer

  def init(%{topics_to_consume: topic}) do
    {:ok, %{topics_to_consume: topic}}
  end

  def start(topic) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{topics_to_consume: []})
    Logger.info("Starting Subscriber for topic - #{topic} - ")
    {:ok, pid}
  end
end
