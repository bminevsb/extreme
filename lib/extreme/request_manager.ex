defmodule Extreme.RequestManager do
  use GenServer
  alias Extreme.{Tools, Configuration, Request, Response, Connection}

  defmodule State do
    defstruct ~w(base_name credentials requests subscriptions)a
  end

  def _name(base_name), do: Module.concat(base_name, RequestManager)

  def _process_supervisor_name(base_name),
    do: Module.concat(base_name, MessageProcessingSupervisor)

  def start_link(base_name, configuration),
    do: GenServer.start_link(__MODULE__, {base_name, configuration}, name: _name(base_name))

  @doc """
  Send IdentifyClient message to EventStore. Called when connection is established.
  """
  def identify_client(connection_name, base_name) do
    base_name
    |> _name()
    |> GenServer.cast({:identify_client, connection_name})
  end

  def send_heartbeat_response(base_name, correlation_id) do
    base_name
    |> _name()
    |> GenServer.cast({:send_heartbeat_response, correlation_id})
  end

  @doc """
  Processes server message as soon as it is completely received via tcp.
  This function is run in `connection` process.
  """
  def process_server_message(base_name, message) do
    :ok =
      base_name
      |> _name()
      |> GenServer.cast({:process_server_message, message})
  end

  @doc """
  Sends `message` as a response to pending request or as a push on subscription.
  `correlation_id` is used to find pending request/subscription.
  """
  def respond_with_server_message(base_name, correlation_id, response) do
    base_name
    |> _name()
    |> GenServer.cast({:respond_with_server_message, correlation_id, response})
  end

  def execute(base_name, message, correlation_id) do
    base_name
    |> _name()
    |> GenServer.call({:execute, correlation_id, message})
  end

  def subscribe_to(base_name, stream, subscriber, resolve_link_tos) do
    base_name
    |> _name()
    |> GenServer.call({:subscribe_to, stream, subscriber, resolve_link_tos})
  end

  def _unregister_subscription(base_name, correlation_id) do
    base_name
    |> _name()
    |> GenServer.cast({:unregister_subscription, correlation_id})
  end

  def read_and_stay_subscribed(base_name, subscriber, params) do
    base_name
    |> _name()
    |> GenServer.call({:read_and_stay_subscribed, subscriber, params})
  end

  ## Server callbacks

  @impl true
  def init({base_name, configuration}) do
    # link me with SubscriptionsSupervisor, since I'm subscription register.
    true =
      Extreme.SubscriptionsSupervisor._name(base_name)
      |> Process.whereis()
      |> Process.link()

    {:ok,
     %State{
       base_name: base_name,
       credentials: Configuration.prepare_credentials(configuration),
       requests: %{},
       subscriptions: %{}
     }}
  end

  @impl true
  def handle_call({:execute, correlation_id, message}, from, %State{} = state) do
    state = %State{state | requests: Map.put(state.requests, correlation_id, from)}

    _in_task(state.base_name, fn ->
      {:ok, message} = Request.prepare(message, state.credentials, correlation_id)
      :ok = Connection.push(state.base_name, message)
    end)

    {:noreply, state}
  end

  def handle_call({:subscribe_to, stream, subscriber, resolve_link_tos}, from, %State{} = state) do
    _start_subscription(self(), from, state.base_name, fn correlation_id ->
      Extreme.SubscriptionsSupervisor.start_subscription(
        state.base_name,
        correlation_id,
        subscriber,
        stream,
        resolve_link_tos
      )
    end)

    {:noreply, state}
  end

  def handle_call({:read_and_stay_subscribed, subscriber, read_params}, from, %State{} = state) do
    _start_subscription(self(), from, state.base_name, fn correlation_id ->
      Extreme.SubscriptionsSupervisor.start_subscription(
        state.base_name,
        correlation_id,
        subscriber,
        read_params
      )
    end)

    {:noreply, state}
  end

  defp _start_subscription(req_manager, from, base_name, fun) do
    _in_task(base_name, fn ->
      correlation_id = Tools.generate_uuid()

      {:ok, subscription} = fun.(correlation_id)

      GenServer.cast(req_manager, {:register_subscription, correlation_id, subscription})

      GenServer.reply(from, {:ok, subscription})
    end)
  end

  @impl true
  def handle_cast({:identify_client, connection_name}, %State{} = state) do
    {:ok, message} = Request.prepare(:identify_client, connection_name, state.credentials)
    :ok = Connection.push(state.base_name, message)
    {:noreply, state}
  end

  def handle_cast({:process_server_message, message}, %State{} = state) do
    correlation_id =
      message
      |> Response.get_correlation_id()

    state.subscriptions[correlation_id]
    |> _process_server_message(message, state)

    {:noreply, state}
  end

  def handle_cast({:send_heartbeat_response, correlation_id}, %State{} = state) do
    {:ok, message} = Request.prepare(:heartbeat_response, correlation_id)
    :ok = Connection.push(state.base_name, message)
    {:noreply, state}
  end

  def handle_cast({:respond_with_server_message, correlation_id, response}, %State{} = state) do
    state =
      case Map.get(state.requests, correlation_id) do
        from when not is_nil(from) ->
          requests = Map.delete(state.requests, correlation_id)
          :ok = GenServer.reply(from, response)
          %{state | requests: requests}
      end

    {:noreply, state}
  end

  def handle_cast({:register_subscription, correlation_id, subscription}, %State{} = state) do
    subscriptions = Map.put(state.subscriptions, correlation_id, subscription)
    {:noreply, %State{state | subscriptions: subscriptions}}
  end

  def handle_cast({:unregister_subscription, correlation_id}, %State{} = state) do
    subscriptions = Map.delete(state.subscriptions, correlation_id)
    requests = Map.delete(state.requests, correlation_id)
    {:noreply, %State{state | requests: requests, subscriptions: subscriptions}}
  end

  ## Helper functions

  defp _in_task(base_name, fun) do
    base_name
    |> _process_supervisor_name()
    |> Task.Supervisor.start_child(fun)
  end

  # message is response to pending request
  defp _process_server_message(nil, message, state) do
    _in_task(state.base_name, fn ->
      message
      |> Response.parse()
      |> _respond_on(state.base_name)
    end)
  end

  # message is for subscription, decoding needs to be done there so we keep the order of incoming messages
  defp _process_server_message(subscription, message, _state),
    do: GenServer.cast(subscription, {:process_push, fn -> Response.parse(message) end})

  defp _respond_on({:client_identified, _correlation_id}, _),
    do: :ok

  defp _respond_on({:heartbeat_request, correlation_id}, base_name),
    do: :ok = send_heartbeat_response(base_name, correlation_id)

  defp _respond_on({:error, :not_authenticated, correlation_id}, base_name),
    do: :ok = respond_with_server_message(base_name, correlation_id, {:error, :not_authenticated})

  defp _respond_on({:error, :bad_request, correlation_id}, base_name),
    do: :ok = respond_with_server_message(base_name, correlation_id, {:error, :bad_request})

  defp _respond_on({_auth, correlation_id, message}, base_name) do
    response = Response.reply(message, correlation_id)
    :ok = respond_with_server_message(base_name, correlation_id, response)
  end
end