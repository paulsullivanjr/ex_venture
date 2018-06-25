defmodule ExampleConsumer do
  use Nostrum.Consumer

  alias Game.Session
  alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}) do
    case msg.content do
      "!who" ->
        player_count =
          Session.Registry.connected_players()
          |> length()
          |> Integer.to_string()

        Api.create_message(msg.channel_id, "There are #{player_count} players online right now.")

      _ ->
        :ignore
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end
end
