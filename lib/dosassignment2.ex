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
    GenServer.call(new_node, {:initialize, algo, count, [prev_node_pid], self()})

    # add the current new node as neighbor to previous node
    GenServer.call(prev_node_pid, {:addNeighbor, [new_node]})

    [new_node] ++ addNextLineNode(new_node, count+1, max, algo)
  end

  def createLineTopology(state) do

    if state.num_nodes > 0 do

      # variable that stores all the nodes known to the server

      {:ok, prev_node_pid} = GenServer.start(MyNode, %{})
      GenServer.call(prev_node_pid, {:initialize, state.algo, 0, [], self()})

      # in line topology node are connected one after another and each node knows previous and next node only
      all_nodes = [prev_node_pid] ++ addNextLineNode(prev_node_pid, 1, state.num_nodes, state.algo)
    else
      []
    end
  end

  def addNextHoneyCombNode(count, max, algo) when count==max do
    []
  end

  def addNextHoneyCombNode(count, max, algo) do
    # create a new actor genserver
    {:ok, new_node} = GenServer.start(MyNode, %{})

    # initalize the genserver with the previous node as the neighbor
    GenServer.call(new_node, {:initialize, algo, count, [], self()})

    [new_node] ++ addNextHoneyCombNode(count+1, max, algo)
  end

  def createListForHoneyComb(all_node_list, pos, line_no, max) when pos>=max do
    []
  end

  def createListForHoneyComb(all_node_list, pos, line_no, max) do
    list =
      if (rem(line_no, 2) > 0) do
        [[[Enum.at(all_node_list,pos)],[],[],[Enum.at(all_node_list,pos+1)],[Enum.at(all_node_list,pos+2)],[],[],[Enum.at(all_node_list,pos+3)]]]
      else
        [[[],[Enum.at(all_node_list,pos)],[Enum.at(all_node_list,pos+1)],[],[],[Enum.at(all_node_list,pos+2)],[Enum.at(all_node_list,pos+3)],[]]]
      end

    list ++ createListForHoneyComb(all_node_list, pos+4, line_no+1, max)
  end

  def getNodeVal(node, pos) do
    Enum.at(Enum.at(node,pos), 0)
  end

  def addRandomHoneyCombNeighbor(node_list) do

    if (Enum.count(node_list)>1) do
      random_node_1 = Enum.random(node_list)
      List.delete(node_list, random_node_1)
      random_node_2 = Enum.random(node_list)
      List.delete(node_list, random_node_2)

      GenServer.call(random_node_1, {:addNeighbor, random_node_2})
      GenServer.call(random_node_2, {:addNeighbor, random_node_1})

      addRandomHoneyCombNeighbor(node_list)
    end
  end

  def addHoneyCombNeighbor(node_list) do

    len = Enum.count(node_list)-1

    for iter <- 0..len do

      cur_node_list   = Enum.at(node_list, iter)
      next_node_list  = Enum.at(node_list, rem(iter+1, len+1))

      if (Enum.count(Enum.at(cur_node_list,0)) != 0) do
        #first and last
        GenServer.call(getNodeVal(cur_node_list,0), {:addNeighbor, [getNodeVal(cur_node_list,7)]})
        GenServer.call(getNodeVal(cur_node_list,7), {:addNeighbor, [getNodeVal(cur_node_list,0)]})
        #center two nodes
        GenServer.call(getNodeVal(cur_node_list,3), {:addNeighbor, [getNodeVal(cur_node_list,4)]})
        GenServer.call(getNodeVal(cur_node_list,4), {:addNeighbor, [getNodeVal(cur_node_list,3)]})
        #across nodes 1
        GenServer.call(getNodeVal(cur_node_list,0), {:addNeighbor, [getNodeVal(next_node_list,1)]})
        GenServer.call(getNodeVal(next_node_list,1), {:addNeighbor, [getNodeVal(cur_node_list,0)]})
        #across nodes 2
        GenServer.call(getNodeVal(cur_node_list,3), {:addNeighbor, [getNodeVal(next_node_list,2)]})
        GenServer.call(getNodeVal(next_node_list,2), {:addNeighbor, [getNodeVal(cur_node_list,3)]})
        #across nodes 3
        GenServer.call(getNodeVal(cur_node_list,4), {:addNeighbor, [getNodeVal(next_node_list,5)]})
        GenServer.call(getNodeVal(next_node_list,5), {:addNeighbor, [getNodeVal(cur_node_list,4)]})
        #across nodes 4
        GenServer.call(getNodeVal(cur_node_list,7), {:addNeighbor, [getNodeVal(next_node_list,6)]})
        GenServer.call(getNodeVal(next_node_list,6), {:addNeighbor, [getNodeVal(cur_node_list,7)]})

      else
        #first and last
        GenServer.call(getNodeVal(cur_node_list,1), {:addNeighbor, [getNodeVal(cur_node_list,2)]})
        GenServer.call(getNodeVal(cur_node_list,2), {:addNeighbor, [getNodeVal(cur_node_list,1)]})
        #center two nodes
        GenServer.call(getNodeVal(cur_node_list,5), {:addNeighbor, [getNodeVal(cur_node_list,6)]})
        GenServer.call(getNodeVal(cur_node_list,6), {:addNeighbor, [getNodeVal(cur_node_list,5)]})
        #across nodes 1
        GenServer.call(getNodeVal(cur_node_list,1), {:addNeighbor, [getNodeVal(next_node_list,0)]})
        GenServer.call(getNodeVal(next_node_list,0), {:addNeighbor, [getNodeVal(cur_node_list,1)]})
        #across nodes 2
        GenServer.call(getNodeVal(cur_node_list,2), {:addNeighbor, [getNodeVal(next_node_list,3)]})
        GenServer.call(getNodeVal(next_node_list,3), {:addNeighbor, [getNodeVal(cur_node_list,2)]})
        #across nodes 3
        GenServer.call(getNodeVal(cur_node_list,5), {:addNeighbor, [getNodeVal(next_node_list,4)]})
        GenServer.call(getNodeVal(next_node_list,4), {:addNeighbor, [getNodeVal(cur_node_list,5)]})
        #across nodes 4
        GenServer.call(getNodeVal(cur_node_list,6), {:addNeighbor, [getNodeVal(next_node_list,7)]})
        GenServer.call(getNodeVal(next_node_list,7), {:addNeighbor, [getNodeVal(cur_node_list,6)]})
      end
    end
  end

  def createHoneyCombTopology(state, with_random_network) do

    num_node =
    if rem(state.num_nodes, 16) != 0 do
      num_node = state.num_nodes - rem(state.num_nodes, 16) + 16
    else
      state.num_nodes
    end

    #create the required number of nodes and get the list of all nodes
    all_nodes = addNextHoneyCombNode(0, num_node, state.algo)

    node_list = createListForHoneyComb(all_nodes, 0, 0, num_node)

    addHoneyCombNeighbor(node_list)

    if (with_random_network) do
      addRandomHoneyCombNeighbor(node_list)
    end

    all_nodes
  end

  def initializeTopology(state) do
    case state.topology do
      @topology_FN    -> Logger.info(@topology_FN)
      @topology_Line  -> createLineTopology(state)
      @topology_R2D   -> Logger.info(@topology_R2D)
      @topology_3DTG  -> Logger.info(@topology_3DTG)
      @topology_HC    -> createHoneyCombTopology(state, false)
      @topology_HCRN  -> createHoneyCombTopology(state, true)
      true            -> []
    end
  end

  @impl true
  def handle_call({:initialize, topology, algo, num_node}, _from, _state) do
    Logger.info("Application Initialization in progress")

    state = %{:num_nodes => num_node, :algo => algo, :topology => topology, :nodes => []}

    Logger.info("Creating topology")

    all_nodes = initializeTopology(state)

    state = %{state | :nodes     => all_nodes}
    state = %{state | :num_nodes => Enum.count(all_nodes)}    #update the num nodes in case extra nodes were added to balance network

    if (num_node != state.num_nodes) do
      Logger.info("Node count changed for maintaining the structure. Original nodes requested: #{num_node}. Actual Node Count: #{state.num_nodes}")
    end

    Logger.info("Application Initialized")

    #IO.inspect(state)
    {:reply, :ok, state}
  end

end
