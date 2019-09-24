

defmodule Main do
  require Logger
  # Dosassignment2

  [num_node_arg, topology, algo] = System.argv

  {num_node, _} = Integer.parse(num_node_arg)

  if (num_node < 1) do
    Logger.info("The number of nodes must be greater than 0.")
  else

    if (topology != Dosassignment2.topology_FN &&
        topology != Dosassignment2.topology_Line &&
        topology != Dosassignment2.topology_R2D &&
        topology != Dosassignment2.topology_3DTG &&
        topology != Dosassignment2.topology_HC &&
        topology != Dosassignment2.topology_HCRN) do

      Logger.info("Invalid Topology Parameter. Current supported topology strings are:\n\t" <> Dosassignment2.topology_FN <> "\n\t" <>
                                                                                               Dosassignment2.topology_Line <> "\n\t" <> Dosassignment2.topology_R2D <> "\n\t" <> Dosassignment2.topology_3DTG <> "\n\t" <> Dosassignment2.topology_HC <> "\n\t" <> Dosassignment2.topology_HCRN)
    else
      if (algo != MyNode.gossip && algo != MyNode.push_sum) do
        Logger.info("Invalid Algorithm Parameter. Current supported algorithm strings are:\n\t" <> MyNode.gossip <> "\n\t" <>
                                                                                                                    MyNode.push_sum)
      else

        #now that we have everything proper start genserver
        {:ok, server_pid} = GenServer.start(Dosassignment2, %{})

        #create topology on the genserver (Must be a call)
        GenServer.call(server_pid, {:initialize, topology, algo, num_node})

        #reset time here for statistics collection for convergence
        #:erlang.statistics(:runtime)
        :erlang.statistics(:wall_clock)

        #initate the process (must be a call)
        GenServer.cast(server_pid, {:startProcess})

        {state, response} = Util.trackTaskCompletion(server_pid)

        IO.puts("response : #{state} #{inspect response}")

        #capture time here for statistics
        {_, wall_clock} = :erlang.statistics(:wall_clock)
        #{_, runtime}    = :erlang.statistics(:runtime)

        IO.puts("Total time for convergence: #{wall_clock}")
      end
    end
  end
end