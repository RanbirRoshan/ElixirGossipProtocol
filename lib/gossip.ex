defmodule MyNode do
  use GenServer
  require Logger

  def init(init_arg) do
    {:ok, init_arg}
  end

  @moduledoc """
  Documentation for Dosassignment2.
  """
  @gossip "Gossip"
  @push_sum "PushSum"
  #@gossip_limit :math.pow(10, 1)

  def gossip do @gossip end
  def push_sum do @push_sum end

  @impl true
  def handle_call({:initialize, algo, node_id, neighbor, parent_pid}, _from, _state) do
    state = %{:algo => algo, :id => node_id+1, :neighbor => neighbor, :parent_pid => parent_pid}

    # add the required component for the gossip protocol
    state=
    if (algo == @gossip) do
      state = Map.put(state, :rumorMessage, nil)
      state = Map.put(state, :rumorMessage, [0,(node_id+1)])
      state = Map.put(state, :limit, 0)
    end

    #IO.inspect(state.neighbor)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:printNeighbor}, _from, state) do
    IO.puts("#{inspect self()} Has Neighbors   #{inspect state.neighbor}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:addNeighbor, neighbor_pid}, _from, state) do
    state = %{state | :neighbor => state.neighbor ++ neighbor_pid}
    #IO.puts("#{inspect self()}   #{inspect state}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:initiate_gossip}, state)  do
    GenServer.cast(state.parent_pid, {:ping})
    GenServer.cast(Enum.random(state.neighbor), {:gossip, state.rumorMessage})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:gossip, rumorMessage}, state) do
    state =
    if (state.limit < 10) do
      GenServer.cast(state.parent_pid, {:ping})
      GenServer.cast(Enum.random(state.neighbor), {:gossip, rumorMessage})
      state
    else
      state
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:print_state}, _from, state) do
    Logger.info("#{inspect self()}  #{state.id}: The state is ")
    {:reply, :ok, state}
  end

  @doc """
  Hello world.

  ## Examples

      iex> Dosassignment2.hello()
      :world

  """
  def hello do
    :world
  end
end