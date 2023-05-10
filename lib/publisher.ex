defmodule Publisher do
  require Logger
  use GenServer

  @impl true
  def init(_init_args) do
    {:ok, %{topic_target: nil}}
  end

  def start() do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    Logger.info("Starting new Publisher")
    {:ok, pid}
  end
end
