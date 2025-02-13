defmodule Util do
  def trackTaskCompletion(server_pid) do
    {state, response} = GenServer.call(server_pid,{:ProcessState}, 1000000)
    if (state == :complete) do
      {state, response}
    else
      :timer.sleep(100)
      trackTaskCompletion(server_pid)
    end
  end
end

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

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  def addNextLineNode(_prev_node_pid, count, max, _algo) when count==max do
    []
  end

  def addNextLineNode(_prev_node_pid, count, max, algo) do
    # create a new actor genserver
    new_node = getSingleNode(algo)

    # initalize the genserver with the previous node as the neighbor
    GenServer.call(new_node, {:initialize, algo, count, [], self()})

    # add the current new node as neighbor to previous node
    #GenServer.call(prev_node_pid, {:addNeighbor, [new_node]})

    [new_node] ++ addNextLineNode(new_node, count+1, max, algo)
  end

  def makeRandomLine(all_nodes, prev_node) do

    if Enum.count(all_nodes) > 0 do
      random_node = Enum.random(all_nodes)

      GenServer.call(random_node, {:addNeighbor, [prev_node]})
      GenServer.call(prev_node, {:addNeighbor, [random_node]})
      makeRandomLine(List.delete(all_nodes, random_node), random_node)
    end
  end

  def createLineTopology(state) do

    if state.num_nodes > 0 do

      # variable that stores all the nodes known to the server

      prev_node_pid = getSingleNode(state.algo)
      GenServer.call(prev_node_pid, {:initialize, state.algo, 0, [], self()})

      # in line topology node are connected one after another and each node knows previous and next node only
      all_nodes = [prev_node_pid] ++ addNextLineNode(prev_node_pid, 1, state.num_nodes, state.algo)

      start = Enum.random(all_nodes)
      makeRandomLine(List.delete(all_nodes, start), start)
      all_nodes
    else
      []
    end
  end

  def createNodeList(count, max, _algo) when count==max do
    []
  end

  def createNodeList(count, max, algo) do
    # create a new actor genserver
    new_node = getSingleNode(algo)

    # initalize the genserver with the previous node as the neighbor
    GenServer.call(new_node, {:initialize, algo, count, [], self()})

    [new_node] ++ createNodeList(count+1, max, algo)
  end

  def createListForHoneyComb(_all_node_list, pos, _line_no, max) when pos>=max do
    []
  end

  def createListForHoneyComb(all_node_list, pos, line_no, max) do
    list =
      if (rem(line_no, 2) > 0) do
        [[[],[Enum.at(all_node_list,pos)],[Enum.at(all_node_list,pos+1)],[],[],[Enum.at(all_node_list,pos+2)],[Enum.at(all_node_list,pos+3)],[]]]
      else
        [[[Enum.at(all_node_list,pos)],[],[],[Enum.at(all_node_list,pos+1)],[Enum.at(all_node_list,pos+2)],[],[],[Enum.at(all_node_list,pos+3)]]]
      end

    list ++ createListForHoneyComb(all_node_list, pos+4, line_no+1, max)
  end

  def getNodeVal(node, pos) do
    Enum.at(Enum.at(node,pos), 0)
  end

  def addRandomHoneyCombNeighbor(node_list) do

    if (Enum.count(node_list)>1) do
      random_node_1 = Enum.random(node_list)
      node_list = List.delete(node_list, random_node_1)
      random_node_2 = Enum.random(node_list)
      node_list = List.delete(node_list, random_node_2)

      GenServer.call(random_node_1, {:addNeighbor, [random_node_2]})
      GenServer.call(random_node_2, {:addNeighbor, [random_node_1]})

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
      state.num_nodes - rem(state.num_nodes, 16) + 16
    else
      state.num_nodes
    end

    #create the required number of nodes and get the list of all nodes
    all_nodes = Enum.shuffle(createNodeList(0, num_node, state.algo))

    node_list = createListForHoneyComb(all_nodes, 0, 0, num_node)

    #IO.inspect(node_list)
    addHoneyCombNeighbor(node_list)

    if (with_random_network) do
      addRandomHoneyCombNeighbor(all_nodes)
    end

    #printNeighborDetails(all_nodes, 0)

    all_nodes
  end

  def addNextFullNode(all_node_list, count, max, algo) do
    if (count < max) do
      # create a new actor genserver
      new_node = getSingleNode(algo)

      # initalize the genserver with all previous nodes as the neighbor
      GenServer.call(new_node, {:initialize, algo, count, all_node_list, self()})

      for item <- all_node_list do
        # add the current new node as neighbor to all nodes
        GenServer.call(item, {:addNeighbor, [new_node]})
      end

      [new_node] ++ addNextFullNode(all_node_list ++ [new_node], count+1, max, algo)
    else
      []
    end
  end

  def getSingleNode(_algo) do
    {:ok, node} =
      #if algo == PushSumNode.push_sum() do
        GenServer.start(PushSumNode, %{})
      #else
      #  GenServer.start(GossipNode, %{})
      #end
    node
  end

  def createFullTopology(state) do

    if state.num_nodes > 0 do

      # variable that stores all the nodes known to the server
      new_node = getSingleNode(state.algo)

      GenServer.call(new_node, {:initialize, state.algo, 0, [], self()})

      # in full topology all node are connected to one  another 
      [new_node] ++ addNextFullNode([new_node], 1, state.num_nodes, state.algo)
    else
      []
    end
  end

  def createListFor3D(all_node_list, cube_edge) do
    square = Kernel.trunc(:math.pow(cube_edge,2))
    for iter <-  1..cube_edge do
      layer = 
        for inner_iter <- 1..cube_edge do
          row =
            for row_iter <- 1..cube_edge do
              pos = (iter-1)*square + (inner_iter-1)*cube_edge + (row_iter-1)
              Enum.at(all_node_list, pos)
            end
          row
        end
        layer
    end   
  end

  def linkTwoRow3d(row1, row2, edge_len) do
    for iter <- 0..(edge_len-1) do
      cur_node   = Enum.at(row1, iter)
      next_node  = Enum.at(row1, rem(iter+1, edge_len))
      GenServer.call(cur_node, {:addNeighbor, [next_node]})
      GenServer.call(next_node, {:addNeighbor, [cur_node]})
      
      GenServer.call(cur_node, {:addNeighbor, [Enum.at(row2, iter)]})
      GenServer.call(Enum.at(row2, iter), {:addNeighbor, [cur_node]})
    end
  end

  def linkTwo3DLevels(level_cur, level_next, edge_len) do
    
    for iter <- 0..(edge_len-1) do    
      cur_row   = Enum.at(level_cur, iter)
      next_row  = Enum.at(level_cur, rem(iter+1, edge_len))
      linkTwoRow3d(cur_row, next_row, edge_len)

      next_level_row = Enum.at(level_next, iter)

      for col <- 0..(edge_len-1) do
        GenServer.call(Enum.at(cur_row, col), {:addNeighbor, [Enum.at(next_level_row, col)]})
        GenServer.call(Enum.at(next_level_row, col), {:addNeighbor, [Enum.at(cur_row, col)]})
      end
    end
  end

  def add3DNeighbor(cube_list, edge_len) do

    for iter <- 0..(edge_len-1) do

      cur_node_list   = Enum.at(cube_list, iter)
      next_node_list  = Enum.at(cube_list, rem(iter+1, edge_len))
        
      linkTwo3DLevels(cur_node_list, next_node_list, edge_len)
    end
  end

  def printNeighborDetails(node_list, pos) do
    if pos < Enum.count(node_list) do
      GenServer.call(Enum.at(node_list, pos), {:printNeighbor})
      printNeighborDetails(node_list, pos+1)
    end
  end

  def ceiling(num) do
    trunc = :erlang.trunc(num)
    cond do
      num - trunc > 0 -> trunc + 1
      true -> trunc
    end
  end

  def create3DTopology(state) do
    #CUBE FUNCTION

    #nearest_cube = ceiling(getNearestCube(state.num_nodes)) # exact cube
   # nearest_cube = math.Floor(getNearestCube(3,state.num_nodes,1e-5)) # exact cube

    #num_node = :math.pow(nearest_cube, 3)

    #create the required number of nodes and get the list of all nodes
    #all_nodes = createNodeList(0, num_node, state.algo)

    #cube_list = createListFor3D(all_nodes, nearest_cube, num_node)

    #add3DNeighbor(cube_list, nearest_cube)

    #all_nodes
  end

  def initializeTopology(state) do
    case state.topology do
      @topology_FN    -> createFullTopology(state) 
      @topology_Line  -> createLineTopology(state)
      @topology_R2D   -> Logger.info(@topology_R2D)
      @topology_3DTG  -> Logger.info(@topology_3DTG)
      @topology_HC    -> createHoneyCombTopology(state, false)
      @topology_HCRN  -> createHoneyCombTopology(state, true)
      true            -> []
    end
  end

  @impl true
  def handle_call({:getPendingRatio}, _from, state) do

    total = Enum.count(state.nodes)
    ratio =
      if(Enum.count(state.completed_childs) == total) do
        1
      else
        val = div(total, total - Enum.count(state.completed_childs))
        if(val>10) do
          10
        else
          val
        end
      end

    #IO.puts("Ratio #{ratio}")
    {:reply, 1/:math.pow(3, ratio), state}
  end

  @impl true
  def handle_call({:ProcessState}, _from, state) do

    #if (state.algo == PushSumNode.gossip()) do
    #  {:reply, {:complete, "Not Implemented"}, state}
    #else
      complete_count = Enum.count(state.completed_childs)
      total = Enum.count(state.nodes)
      completionratio = complete_count/total;
      cond do
        (Enum.count(Enum.uniq(state.nodes)) == Enum.count(Enum.uniq(state.completed_childs))) ->
          {:reply, {:complete, "coverged by 100%"}, state}
        (state.topology == @topology_3DTG && (:os.system_time(:millisecond) - state.lastCompletionTime) > 5500 && completionratio>=0.8) ->
          {:reply, {:complete, "converged by #{completionratio*100}%"}, state}
        (state.topology == @topology_R2D && (:os.system_time(:millisecond) - state.lastCompletionTime) > 5500 && completionratio>=0.75) ->
          {:reply, {:complete, "converged by #{completionratio*100}%"}, state}
        (state.topology == @topology_HCRN && (:os.system_time(:millisecond) - state.lastCompletionTime) > 10500 && completionratio>=0.825) ->
          {:reply, {:complete, "converged by #{completionratio*100}%"}, state}
        (state.topology == @topology_HC && (:os.system_time(:millisecond) - state.lastCompletionTime) > 10500 && completionratio>=0.8) ->
          {:reply, {:complete, "converged by #{completionratio*100}%"}, state}
        (state.topology == @topology_FN && (:os.system_time(:millisecond) - state.lastCompletionTime) > 5500 && completionratio>=0.9) ->
          {:reply, {:complete, "converged by #{completionratio*100}%"}, state}
        (state.topology == @topology_Line && (:os.system_time(:millisecond) - state.lastCompletionTime) > 5500 && completionratio>=0.85) ->
          {:reply, {:complete, "converged by #{completionratio*100}%"}, state}
        (state.topology == @topology_3DTG && (:os.system_time(:millisecond) - state.lastCompletionTime) > 5500 && completionratio<0.8) ->
          {:reply, {:inprogress, ""}, state}
        (state.topology == @topology_R2D && (:os.system_time(:millisecond) - state.lastCompletionTime) > 5500 && completionratio<0.75) ->
          {:reply, {:inprogress, ""}, state}
        (state.topology == @topology_HCRN && (:os.system_time(:millisecond) - state.lastCompletionTime) > 10500 && completionratio<0.825) ->
          {:reply, {:inprogress, ""}, state}
        (state.topology == @topology_HC && (:os.system_time(:millisecond) - state.lastCompletionTime) > 10500 && completionratio<0.8) ->
          {:reply, {:inprogress, ""}, state}
        (state.topology == @topology_FN && (:os.system_time(:millisecond) - state.lastCompletionTime) > 5500 && completionratio<0.9) ->
          {:reply, {:inprogress, ""}, state}
        (state.topology == @topology_Line && (:os.system_time(:millisecond) - state.lastCompletionTime) > 5500 && completionratio<0.85) ->
          {:reply, {:inprogress, ""}, state}
        true->
          {:reply, {:inprogress, ""}, state}

      end
    #end
  end

  @impl true
  def handle_call({:initialize, topology, algo, num_node}, _from, _state) do
    Logger.info("Application Initialization in progress")

    time = :os.system_time(:millisecond)
    state = %{:num_nodes => num_node, :lastCompletionTime => time, :algo => algo, :topology => topology, :nodes => [], :completed_childs => [], :last_ping => time, :start => time}

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

  @impl true
  def handle_cast({:inform_completion, child_id}, state) do
    list = state.completed_childs ++ [child_id]
    state = %{state | :completed_childs => list}
    if state.algo == PushSumNode.push_sum() do
      Logger.info("yet to complete #{Enum.count(state.nodes) - Enum.count(list)}")
    end
    state = %{state|:lastCompletionTime =>:os.system_time(:millisecond)}
    {:noreply, state}
  end

  @impl true
  def handle_cast({:startProcess}, state) do
    #if state.algo == PushSumNode.gossip() do
    #  GenServer.cast(Enum.random(state.nodes), {:initiate_algo})
    #else
      GenServer.cast(Enum.random(state.nodes), {:initiate_algo})
    #end
    state = %{state|:last_ping =>:os.system_time(:millisecond)}
    state = %{state|:lastCompletionTime =>:os.system_time(:millisecond)}
    {:noreply, state}
  end

  @impl true
  def handle_cast({:ping}, state) do
    #IO.puts("ping recieved #{inspect :os.system_time(:millisecond)}")
    state = %{state | :last_ping => :os.system_time(:millisecond)}
    {:noreply, state}
  end

  def printChildStates(list, i, max) do
    if i != max do
      GenServer.call(Enum.at(list, i), {:print_state})
      printChildStates(list, i+1, max)
    end
  end

  def printStates(list) do
    elem = Enum.at(list, 0)
    GenServer.call(elem, {:print_state})
    if Enum.count(list) > 1 do
      printStates(List.delete(list, elem))
    end
  end

end
