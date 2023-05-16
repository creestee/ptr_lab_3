defmodule MessageBroker do
  require Logger
  use Application

  @client_ports [6060, 7070, 8080]

  def start(_type, _args) do
    SubscriberHandler.start()

    Connection.Supervisor.start()
    Publisher.Supervisor.start()
    Subscriber.Supervisor.start()

    Enum.each(@client_ports, fn port -> Connection.Supervisor.new_connection(port) end)
    {:ok, self()}
  end
end
