defmodule Publisher.Supervisor do
  use DynamicSupervisor

  def start() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new_publisher(socket) do
    spec = %{
      id: :"publisher_#{socket}",
      start: {Publisher, :start, []},
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
