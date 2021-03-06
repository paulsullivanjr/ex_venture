defmodule Game.Command.ChannelsTest do
  use Data.ModelCase
  doctest Game.Command.Channels

  alias Game.Channel
  alias Game.Command.Channels
  alias Game.Message

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()
    Game.Channels.clear()

    %Data.Channel{id: 1, name: "global", color: "red"} |> insert_channel()
    %Data.Channel{id: 2, name: "newbie", color: "yellow"} |> insert_channel()

    user = %{id: 10, name: "Player", save: %{channels: ["global"]}}
    %{socket: :socket, user: user}
  end

  test "parsing out channels that exist" do
    assert {"global", "hi"} = Channels.parse("global hi")
    assert {"newbie", "hi"} = Channels.parse("newbie hi")
    assert {:error, :bad_parse, "unknown hi"} = Channels.parse("unknown hi")
  end

  test "list out channels", %{socket: socket} do
    :ok = Channel.join("global")
    :ok = Channel.join("newbie")

    :ok = Channels.run({}, %{socket: socket})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(global), echo)
    assert Regex.match?(~r(newbie), echo)
  end

  describe "broadcasting messages" do
    setup %{user: user} do
      state = %{socket: :socket, user: user}

      %{state: state}
    end

    test "send a message to a channel", %{state: state} do
      :ok = Channel.join("global")

      :ok = Channels.run({"global", "hello"}, state)

      assert_receive {:channel, {:broadcast, "global", %Message{message: "Hello."}}}
    end
  end

  test "does not send a message if the user is not subscribed to the channel", %{socket: socket, user: user} do
    :ok = Channel.join("newbie")

    :ok = Channels.run({"newbie", "hello"}, %{socket: socket, user: user})

    refute_receive {:channel, {:broadcast, "global", %Message{message: "Hello."}}}, 50
  end

  test "join a channel", %{socket: socket} do
    :ok = Channels.run({:join, "global"}, %{socket: socket, user: %{save: %{channels: []}}})

    assert_receive {:channel, {:joined, "global"}}
  end

  test "join a channel - already joined", %{socket: socket, user: user} do
    :ok = Channels.run({:join, "global"}, %{socket: socket, user: user})

    refute_receive {:channel, {:joined, "global"}}, 50
  end

  test "limit to official channels on a join", %{socket: socket, user: user} do
    :ok = Channels.run({:join, "new-channel"}, %{socket: socket, user: user})

    refute_receive {:channel, {:joined, "new-channel"}}, 50
  end

  test "leave a channel", %{socket: socket, user: user} do
    :ok = Channel.join("global")

    :ok = Channels.run({:leave, "global"}, %{socket: socket, user: user})

    assert_receive {:channel, {:left, "global"}}
  end

  test "leave a channel - no in channel", %{socket: socket, user: user} do
    :ok = Channels.run({:leave, "newbie"}, %{socket: socket, user: user})

    refute_receive {:channel, {:left, "newbie"}}, 50
  end
end
