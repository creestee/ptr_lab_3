defmodule MessageBroker do
  require Logger
  use Application

  def start(_type, _args) do
    SubscriberHandler.start()
    Connection.start(8080)
    Connection.start(7070)
		{:ok, self()}
  end
end
