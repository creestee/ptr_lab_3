defmodule Subscriber do
  require Logger
  use GenServer

  def init(_args) do
    {:ok, %{topics_to_consume: []}}
  end

  def start() do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    Logger.info("[ Starting a new Subscriber ]")
    {:ok, pid}
  end
end
