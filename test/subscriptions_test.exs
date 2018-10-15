defmodule ExtremeSubscriptionsTest do
  use ExUnit.Case, async: false
  alias ExtremeTest.Helpers
  alias ExtremeTest.Events, as: Event
  require Logger

  defmodule Subscriber do
    use GenServer

    def start_link(),
      do: GenServer.start_link(__MODULE__, self())

    def received_events(server),
      do: GenServer.call(server, :received_events)

    @impl true
    def init(sender),
      do: {:ok, %{sender: sender, received: []}}

    @impl true
    def handle_call(:received_events, _from, state) do
      result =
        state.received
        |> Enum.reverse()
        |> Enum.map(fn e ->
          data = e.event.data
          :erlang.binary_to_term(data)
        end)

      {:reply, result, state}
    end

    def handle_call({:on_event, event} = message, _from, state) do
      send(state.sender, message)
      {:reply, :ok, %{state | received: [event | state.received]}}
    end

    def handle_call({:on_event, event, _correlation_id} = message, _from, state) do
      send(state.sender, message)
      {:reply, :ok, %{state | received: [event | state.received]}}
    end

    @impl true
    def handle_info({:extreme, _} = message, state) do
      send(state.sender, message)
      {:noreply, state}
    end

    def handle_info({:extreme, _, _, _} = message, state) do
      send(state.sender, message)
      {:noreply, state}
    end

    def handle_info(:caught_up, state) do
      send(state.sender, :caught_up)
      {:noreply, state}
    end
  end

  describe "subscribe_to/3" do
    test "subscription to existing stream is success" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # :caught_up is not received on subscription without previous read
      refute_receive :caught_up

      # write more events after subscription
      num_additional_events = 1000

      events2 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert rest events have arrived
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events2

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "subscription to non existing stream is success" do
      # subscribe to stream
      stream = Helpers.random_stream_name()
      {:warn, :non_existing_stream} = TestConn.execute(Helpers.read_events(stream))
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events))

      # assert rest events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "subscription to soft deleted stream is success" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))

      # soft delete stream
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, false))
      {:warn, :stream_soft_deleted, 2} = TestConn.execute(Helpers.read_events(stream))

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two more events after subscription
      events2 = [%Event.PersonCreated{name: "4"}, %Event.PersonCreated{name: "5"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert rest events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events2

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "soft deleting stream while subscription exists doesn't affect subscription" do
      stream = Helpers.random_stream_name()

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events2 = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # soft delete stream
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, false))
      assert {:warn, :stream_soft_deleted, 1} = TestConn.execute(Helpers.read_events(stream))

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2
      # subscription is alive
      assert Process.alive?(subscription)
      assert Process.alive?(subscriber)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "hard deleting stream will close its subscription" do
      stream = Helpers.random_stream_name()

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events2 = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # hard delete stream
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, true))
      assert {:error, :stream_hard_deleted} = TestConn.execute(Helpers.read_events(stream))

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2
      # ensure information of deleted stream is received
      assert_receive {:extreme, :stream_hard_deleted}
      # subscription is dead, but subscriber may survive
      assert Process.alive?(subscriber)
      :timer.sleep(10)
      refute Process.alive?(subscription)

      Helpers.assert_no_leaks(TestConn)
    end

    test "events are not pushed after unsubscribe" do
      stream = Helpers.random_stream_name()

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # push events
      events1 =
        1..3
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))

      # ensure events are received
      for _ <- 1..3, do: assert_receive({:on_event, _event})

      # unsubscribe from stream
      Helpers.unsubscribe(TestConn, subscription)
      assert_receive {:extreme, :unsubscribed}

      # write more events after unsubscribe
      events2 =
        4..8
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert new events are not received
      for _ <- 1..5, do: refute_receive({:on_event, _event})

      Helpers.assert_no_leaks(TestConn)
    end
  end

  describe "read_and_stay_subscribed/6" do
    test "read events and stay subscribed for existing stream is ok" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2)

      # assert first events are received
      for _ <- 1..3, do: assert_receive({:on_event, _event})

      # assert :caught_up is received when existing events are read
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events2 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events1 ++ events2

      {:ok, response} = TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events1 ++ events2 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "read events and stay subscribed for non existing stream is ok" do
      stream = Helpers.random_stream_name()
      {:warn, :non_existing_stream} = TestConn.execute(Helpers.read_events(stream))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 20)

      # assert :caught_up is received when existing events are read
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events

      {:ok, response} = TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "read events and stay subscribed for soft deleted stream is ok" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, false))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2)

      # assert first events are receiveD
      for _ <- 1..3, do: refute_receive({:on_event, _event})

      # assert :caught_up is received when existing events are read
      assert_receive {:extreme, :warn, :stream_soft_deleted, ^stream}
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events2 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2

      {:ok, response} = TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events2 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "read events and stay subscribed for recreated stream is ok" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      events2 = [
        %Event.PersonCreated{name: "4"},
        %Event.PersonCreated{name: "5"},
        %Event.PersonCreated{name: "6"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, false))
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 3)

      # assert first events are receiveD
      for _ <- 1..3, do: assert_receive({:on_event, _event})

      # assert :caught_up is received when existing events are read
      refute_receive {:extreme, :warn, :stream_soft_deleted, ^stream}
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events3 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x + 6}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events3))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2 ++ events3

      {:ok, response} = TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events2 ++ events3 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "read events and stay subscribed for hard deleted stream is not ok" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, true))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2)

      # assert :caught_up is received when existing events are read
      assert_receive {:extreme, :error, :stream_hard_deleted, ^stream}

      refute Process.alive?(subscription)
      Helpers.assert_no_leaks(TestConn)
    end

    test "events written while reading stream are also pushed to client in correct order" do
      stream = Helpers.random_stream_name()
      num_events = 1_000
      # prepopulate stream
      events1 =
        1..num_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      events2 =
        1..num_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x + num_events}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 20)

      spawn(fn ->
        {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))
        Logger.debug("Second pack of events written")
      end)

      # assert first events are received
      for _ <- 1..num_events, do: assert_receive({:on_event, _event}, 500)
      Logger.debug("First pack of events received")

      # assert second pack of events is received as well
      for _ <- 1..num_events, do: assert_receive({:on_event, _event}, 500)

      # assert :caught_up is received when existing events are read
      assert_receive :caught_up

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events1 ++ events2

      {:ok, response} = TestConn.execute(Helpers.read_events(stream, 0, 2_000))

      assert events1 ++ events2 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end
  end
end