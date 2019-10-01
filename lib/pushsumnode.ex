defmodule PushSumNode do
  use GenServer
  require Logger

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @moduledoc """
  Documentation for PushSumNode.
  """
  @gossip "Gossip"
  @push_sum "PushSum"
  @push_sum_limit 1/:math.pow(10, 10)
  @gossip_limit 10

  def gossip do @gossip end
  def push_sum do @push_sum end

  @impl true
  def handle_call({:initialize, algo, node_id, neighbor, parent_pid}, _from, _state) do
    state = %{:algo => algo, :id => node_id+1, :neighbor => neighbor, :all_neighbor => neighbor, :parent_pid => parent_pid}

    # add the required component for the gossip protocol
    state=
    if (algo == @push_sum) do
      state = Map.put(state, :s, node_id)
      state = Map.put(state, :w, 1)
      Map.put(state, :sByW, [0,0,(node_id+1)])
    else
      state = Map.put(state, :gossip, "")
      Map.put(state, :gossipHeardCount, 0)
    end

    state = Map.put(state, :proceed, true)
    state = Map.put(state, :terminated, false)
    state = Map.put(state, :slaveStartPending, true)
    state = Map.put(state, :slavePid, self())
    state = Map.put(state, :lastPing, 0)
    #IO.inspect(state.neighbor)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:getState}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:printNeighbor}, _from, state) do
    IO.puts("#{inspect self()} Has Neighbors   #{inspect state.neighbor}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:print_state}, _from, state) do
    Logger.info("#{inspect self()}  #{state.id}: The state is s=#{state.s} w=#{state.w} s/w=#{inspect state.sByW}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:addNeighbor, neighbor_pid}, _from, state) do
    state = %{state | :neighbor => state.neighbor ++ neighbor_pid}
    state = %{state | :all_neighbor => state.all_neighbor ++ neighbor_pid}
    #IO.puts("#{inspect self()}   #{inspect state}")
    {:reply, :ok, state}
  end

  def getLastestMsg(old_msg, factor) do
    #IO.puts(factor)
    #try do
      receive  do
        msg -> getLastestMsg(msg, factor)
      after
        factor -> old_msg
      end
    #catch
    #  _, _ -> Logger.info("timexc______________________________________ #{factor}")
    #end
  end

  def communicateWithNeighbors(state, factor) do
    val = 100*factor
    val =
      if is_integer(val) do
        val
      else
        trunc(val)
      end

    state =
    try do
      getLastestMsg(state, val)
    catch
      _ -> Logger.info("______________________________________ #{val}")
       # getLastestMsg(state, 1)
    end

    if state.proceed == false do
      :timer.sleep(100)
      communicateWithNeighbors(state, 1)
    else
      if Enum.count(state.neighbor) > 0 do
        if state.proceed do
          random_node = Enum.random(state.neighbor)
          #IO.puts("Random Node: #{inspect random_node}")
          if (state.algo == @push_sum) do
            GenServer.cast(random_node, {:push_sum, state.s, state.w})
          else
            GenServer.cast(random_node, {:gossip, state.gossip})
          end
          if Enum.count(state.neighbor) == 1 do
            :timer.sleep(50)
          end
          if factor > 0.4 do
            :timer.sleep(150)
          end
        end
        communicateWithNeighbors(state, GenServer.call(state.parent_pid, {:getPendingRatio}))
      else
        :timer.sleep(5000)#  IO.puts ("none to send")
      end
    end
  end

  def initiateSlaves(state) do
    demon = spawn fn() -> communicateWithNeighbors(%{:proceed=>false}, 1) end
    #IO.puts("slave Initiated #{inspect demon}")
    state = %{state | :slavePid => demon}
    state = %{state | :slaveStartPending => false}
    state
  end

  @impl true
  def handle_cast({:initiate_algo}, state)  do
    GenServer.cast(state.parent_pid, {:ping})
    if state.algo == @push_sum do
      GenServer.cast(Enum.random(state.neighbor), {:push_sum, state.s, state.w})
    else
      GenServer.cast(Enum.random(state.neighbor), {:gossip, "GossipText"})
    end
    state = initiateSlaves(state)
    if (state.slavePid != self()) do
      send(state.slavePid, state)
    end
    {:noreply, state}
  end

  @impl true
  def handle_cast({:inform_completion, source}, state) do
    neighbor = List.delete(state.neighbor, source)
    state = %{state|:neighbor=>neighbor}
    if Enum.count(state.neighbor)>0  && state.slavePid != self() do
      send(state.slavePid, state)
    end

    if Enum.count(state.neighbor) == 0 && state.terminated do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:gossip, gossip_text}, state) do

    state =
      if (state.terminated == false) do

        state =
          if (state.slaveStartPending) do
            initiateSlaves(state)
          else
            state
          end

        state =
        if (state.gossip == gossip_text) do
          %{state | :gossipHeardCount => state.gossipHeardCount + 1}
        else
          state = %{state | :gossip => gossip_text}
          %{state | :gossipHeardCount => 0}
        end

        state =
          if (state.gossipHeardCount == @gossip_limit) do
            for item <- state.neighbor do
              GenServer.cast(item, {:inform_completion, self()})
            end
            #IO.puts("Converged #{inspect self()}")
            GenServer.cast(state.parent_pid, {:inform_completion, self()})
            %{state | :terminated => true}
          else
            state
          end

        state =
          if :os.system_time(:millisecond) - state.lastPing > 500 do
            time = :os.system_time(:millisecond)
            GenServer.cast(state.parent_pid, {:ping})
            %{state | :lastPing => time}
          else
            state
          end
        #IO.puts("#{inspect self()} #{inspect sByw}")

        if Enum.count(state.neighbor) > 0 do
          send(state.slavePid, state)
        end
        if Enum.count(state.neighbor)>0 do
            GenServer.cast(Enum.random(state.neighbor), {:gossip, state.gossip})
        end
        state
      else
        state
      end

    if Enum.count(state.neighbor) == 0 && state.terminated do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:push_sum, s, w}, state) do
    state =
    if (state.terminated == false) do

      state =
      if (state.slaveStartPending) do
        initiateSlaves(state)
      else
        state
      end

      s_new = (s + state.s)/2
      w_new = (w + state.w)/2

      sByw = List.delete_at(state.sByW,0)
      sByw = sByw++ [s_new/w_new]

      state =
      if (:erlang.abs(Enum.at(sByw, 0) - Enum.at(sByw, 1)) < @push_sum_limit &&
            :erlang.abs(Enum.at(sByw, 2) - Enum.at(sByw, 1)) < @push_sum_limit &&
            :erlang.abs(Enum.at(sByw, 0) - Enum.at(sByw, 1)) < @push_sum_limit) do
        for item <- state.neighbor do
          GenServer.cast(item, {:inform_completion, self()})
        end
        IO.puts("Converged #{inspect self()} #{inspect self()} #{inspect sByw}")
        GenServer.cast(state.parent_pid, {:inform_completion, self()})
        %{state | :terminated => true}
      else
        state
      end

      state =
      if :os.system_time(:millisecond) - state.lastPing > 500 do
        time = :os.system_time(:millisecond)
        GenServer.cast(state.parent_pid, {:ping})
        %{state | :lastPing => time}
      else
        state
      end
      #IO.puts("#{inspect self()} #{inspect sByw}")

      #update the state variables
      state = %{state | :sByW => sByw}
      state = %{state | :s => s_new}
      state = %{state | :w => w_new}
      if Enum.count(state.neighbor) > 0 do
        send(state.slavePid, state)
      end
      if Enum.count(state.neighbor)>0 do
        GenServer.cast(Enum.random(state.neighbor), {:push_sum, s_new, w_new})
      end
      state
    else
      state
    end

    if Enum.count(state.neighbor) == 0 && state.terminated do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
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