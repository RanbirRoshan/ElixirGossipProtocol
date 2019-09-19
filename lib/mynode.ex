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
  def handle_call({:initialize, algo, node_id, neighbor}, _from, _state) do
    state = %{:algo => algo, :id => node_id, :neighbor => neighbor}
    IO.inspect(state.neighbor)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:addNeighbor, neighbor_pid}, _from, state) do
    state = %{state | :neighbor => state.neighbor ++ neighbor_pid}
    IO.puts("#{inspect self()}   #{inspect state}")
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