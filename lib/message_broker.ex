defmodule MessageBroker do
  require Logger
  use Application

  def start(_type, _args) do
    # Connection.start(8080)
		{:ok, self()}
  end
end
