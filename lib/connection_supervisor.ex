defmodule Connection.Supervisor do
  use DynamicSupervisor

  def start() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new_connection(port) do
    spec = %{
      id: :"connection_#{port}",
      start: {Connection, :start, [port]},
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
