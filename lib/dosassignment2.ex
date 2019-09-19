import MyNode
defmodule Dosassignment2 do
  use GenServer
  require Logger
  @moduledoc """
  Documentation for Dosassignment2.
  """
  @topology_FN "FullNetwork"
  @topology_Line "Line"
  @topology_R2D "Random2DGrid"
  @topology_3DTG "3DTorusGrid"
  @topology_HC "HoneyComb"
  @topology_HCRN "HoneyCombRandomNeighbor"

  def topology_FN do @topology_FN  end
  def topology_Line do @topology_Line end
  def topology_R2D do @topology_R2D end
  def topology_3DTG do @topology_3DTG end
  def topology_HC do @topology_HC end
  def topology_HCRN do @topology_HCRN end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def addNextLineNode(prev_node_pid, count, max, algo) when count==max do
    []
  end

  def addNextLineNode(prev_node_pid, count, max, algo) do
    # create a new actor genserver
    {:ok, new_node} = GenServer.start(MyNode, %{})

    # initalize the genserver with the previous node as the neighbor
    GenServer.call(new_node, {:initialize, algo, count, [prev_node_pid]})

    # add the current new node as neighbor to previous node
    GenServer.call(prev_node_pid, {:addNeighbor, [new_node]})

    [new_node] ++ addNextLineNode(new_node, count+1, max, algo)
  end


  def createLineTopology(state) do

    if state.num_nodes > 0 do

      # variable that stores all the nodes known to the server

      {:ok, prev_node_pid} = GenServer.start(MyNode, %{})
      GenServer.call(prev_node_pid, {:initialize, state.algo, 0, []})

      # in line topology node are connected one after another and each node knows previous and next node only
      all_nodes = [prev_node_pid] ++ addNextLineNode(prev_node_pid, 1, state.num_nodes, state.algo)
    else
      []
    end
  end

  def initializeTopology(state) do
    IO.puts (state.topology)
    case state.topology do
      @topology_FN    -> Logger.info(@topology_FN)
      @topology_Line  -> createLineTopology(state)
      @topology_R2D   -> Logger.info(@topology_R2D)
      @topology_3DTG  -> Logger.info(@topology_3DTG)
      @topology_HC    -> Logger.info(@topology_HC)
      @topology_HCRN  -> Logger.info(@topology_HCRN)
      true            -> []
    end
  end

  @impl true
  def handle_call({:initialize, topology, algo, num_node}, _from, _state) do
    Logger.info("Application Initialization in progress")

    state = %{:num_nodes => num_node, :algo => algo, :topology => topology, :nodes => []}

    Logger.info("Creating topology")

    all_nodes = initializeTopology(state)

    state = %{state | :nodes => all_nodes}

    Logger.info("Application Initialized")

    IO.inspect(state)
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
