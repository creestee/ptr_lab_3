defmodule Publisher do
  require Logger
  use GenServer

  def init(%{name: publisher_name, topic_target: topic}) do
    {:ok, %{name: publisher_name, topic_target: topic}}
  end

  def start(name, topic) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{name: name, topic_target: topic})
    Logger.info("Starting Publisher with name - #{name} - ")
    {:ok, pid}
  end
end
