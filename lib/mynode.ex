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

  def gossip do @gossip end
  def push_sum do @push_sum end

  @impl true
  def handle_call({:initialize, algo, node_id, neighbor, parent_pid}, _from, _state) do
    state = %{:algo => algo, :id => node_id+1, :neighbor => neighbor, :parent_pid => parent_pid}

    # add the required component for the gossip protocol
    if (algo == @gossip) do
      state = Map.put(state, :s, node_id)
      state = Map.put(state, :w, 1)
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