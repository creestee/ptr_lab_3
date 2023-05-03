defmodule Serialization do
  require Logger
  use GenServer

  def init(_init_args) do
    {:ok, nil}
  end

  def start() do
    GenServer.start_link(__MODULE__, nil)
  end
end
