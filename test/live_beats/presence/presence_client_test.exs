defmodule Phoenix.Presence.ClientTest do
  use ExUnit.Case

  alias Phoenix.Presence.Client.PresenceMock
  alias Phoenix.Presence.Client

  @pubsub LiveBeats.PubSub
  @client Phoenix.Presence.Client.Mock
  @presence LiveBeatsWeb.Presence

  @presence_client_opts [client: @client, pubsub: @pubsub, presence: @presence]

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(LiveBeats.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    :ok
  end

  test "When a new process is tracked, a topic key is added to the topics state" do
    presence_key = 1
    topic = topic(100)

    {:ok, presence_client} = Client.start_link(@presence_client_opts)
    {:ok, presence_process} = PresenceMock.start_link(id: presence_key)

    Phoenix.PubSub.subscribe(@pubsub, topic)
    Process.monitor(presence_process)

    PresenceMock.track(presence_client, presence_process, topic, presence_key)

    assert Process.alive?(presence_process)

    assert_receive %{event: "presence_diff"}

    client_state = :sys.get_state(presence_client)

    assert %{topics: %{^topic => %{"1" => [%{phx_ref: _ref}]}}} = client_state
  end

  test "topic is removed from the topics state when there is no more presences" do
    presence_key = 1
    topic = topic(100)

    {:ok, presence_client} = Client.start_link(@presence_client_opts)
    {:ok, presence_process} = PresenceMock.start_link(id: presence_key)

    Phoenix.PubSub.subscribe(@pubsub, topic)
    Process.monitor(presence_process)

    PresenceMock.track(presence_client, presence_process, topic, presence_key)

    assert Process.alive?(presence_process)

    assert_receive %{event: "presence_diff"}

    client_state = :sys.get_state(presence_client)

    assert %{topics: %{^topic => %{"1" => [%{phx_ref: _ref}]}}} = client_state

    send(presence_process, :quit)

    assert_receive {:DOWN, _ref, :process, ^presence_process, _reason}

    client_state = :sys.get_state(presence_client)

    assert %{topics: %{}} = client_state
  end

  defp topic(id) do
    "mock_topic:#{id}"
  end
end
