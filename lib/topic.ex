defmodule Topic do
  require Logger
  use GenServer

  def init(name) do
    {:ok, %{name: name, messages: []}}
  end

  def start(name) do
    GenServer.start_link(__MODULE__, name)
  end

end
