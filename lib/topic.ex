defmodule Topic do
  require Logger
  use GenServer

  def init(_args) do
    {:ok, nil}
  end

  def start(name) do
    Logger.info("A new topic #{name} was created")
    GenServer.start_link(__MODULE__, :ok, name: String.to_atom(name))
  end

  def handle_call({:send, message, _topic}, _from, state) do
    Logger.info message
    {:reply, :ok, state}
  end

  def send_message(message, topic) do
    :ok = GenServer.call(:"#{topic}", {:send, message, topic})
  end
end
