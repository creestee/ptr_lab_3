defmodule MessageBroker do
  require Logger
  use Application

  def start(_type, _args) do
    SubscriberHandler.start()
		{:ok, self()}
  end
end
