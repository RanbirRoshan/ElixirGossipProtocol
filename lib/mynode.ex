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
  @push_sum_limit :math.pow(10, -10)

  def gossip do @gossip end
  def push_sum do @push_sum end

  @impl true
  def handle_call({:initialize, algo, node_id, neighbor, parent_pid}, _from, _state) do
    state = %{:algo => algo, :id => node_id+1, :neighbor => neighbor, :parent_pid => parent_pid}

    # add the required component for the gossip protocol
    state=
    if (algo == @push_sum) do
      state = Map.put(state, :s, node_id)
      state = Map.put(state, :w, 1)
      state = Map.put(state, :sByW, [0,0,(node_id+1)])
      state = Map.put(state, :terminated, false)
    end

    #IO.inspect(state.neighbor)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:addNeighbor, neighbor_pid}, _from, state) do
    state = %{state | :neighbor => state.neighbor ++ neighbor_pid}
    #IO.puts("#{inspect self()}   #{inspect state}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:initiate_push_sum}, state)  do
    GenServer.cast(state.parent_pid, {:ping})
    GenServer.cast(Enum.random(state.neighbor), {:push_sum, state.s, state.w})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:push_sum, s, w}, state) do
    state =
    if (state.terminated == false) do

      s_new = (s + state.s)/2
      w_new = (w + state.w)/2

      sByw = List.delete_at(state.sByW,0)
      sByw = sByw++ [s_new/w_new]

      state =
      if (:erlang.abs(Enum.at(sByw, 0) - Enum.at(sByw, 1)) < @push_sum_limit &&
            :erlang.abs(Enum.at(sByw, 2) - Enum.at(sByw, 1)) < @push_sum_limit &&
            :erlang.abs(Enum.at(sByw, 0) - Enum.at(sByw, 1)) < @push_sum_limit) do
        GenServer.cast(state.parent_pid, {:informCompletion, self()})
        state = %{state | :terminated => true}
      else
        state
      end

      GenServer.cast(state.parent_pid, {:ping})

      #update the state variables
      state = %{state | :sByW => sByw}
      state = %{state | :s => s_new}
      state = %{state | :w => w_new}

      GenServer.cast(Enum.random(state.neighbor), {:push_sum, s_new, w_new})
      state
    else
      state
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:print_state}, _from, state) do
    Logger.info("#{inspect self()}  #{state.id}: The state is s=#{state.s} w=#{state.w} s/w=#{inspect state.sByW}")
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