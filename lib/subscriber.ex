defmodule Subscriber do
  require Logger
  use GenServer

  def init(%{name: subscriber_name, topic_to_consume: topic}) do
    {:ok, %{name: subscriber_name, topic_to_consume: topic}}
  end

  def start(name, topic) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{name: name, topic_to_consume: topic})
    Logger.info("Starting Subscriber with name - #{name} - ")
    {:ok, pid}
  end
end
