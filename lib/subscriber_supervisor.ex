defmodule Subscriber.Supervisor do
  use DynamicSupervisor

  def start() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new_subscriber(socket) do
    spec = %{
      id: :"subscriber_#{socket}",
      start: {Subscriber, :start, []},
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
