use Mix.Config

defmodule Blitzy.CLI do
  require Logger

  def main(args) do
    Application.get_env(:blitzy, :master_node)
    |> Node.start()

    Application.get_env(:blitzy, :slave_nodes)
    |> Enum.each(&Node.connect(&1))

    args
    |> parse_args
    |> process_options([node() | Node.list()])
  end

  defp parse_args(args) do
    OptionParser.parse(args, aliases: [n: :requests], strict: [requests: :integer])
  end

  defp process_options(options, nodes) do
    case options do
      {[requests: n], [url], []} -> do_requests(n, url, nodes)
      _ -> help()
    end
  end

  defp do_requests(n_requests, url, nodes) do
    Logger.info "Pummelling #{url} with #{n_requests} requests"

    total_nodes = Enum.count(nodes)
    req_per_node = div(n_requests, total_nodes)

    nodes
    |> Enum.flat_map(fn node ->
      1..req_per_node
      |> Enum.map(fn _ ->
        Task.Supervisor.async({Blitzy.TasksSupervisor, node}, Blitzy.Worker, :start, [url])
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results
  end

  defp parse_results(results) do
    {success, _failures} =
      results
      |> Enum.partition(fn x ->
        case x do
          {:ok, _} -> true
          _ -> false
        end
      end)

    total_workers = Enum.count(results)
    total_success = Enum.count(success)
    total_failures = total_workers - total_success

    data =
      success
      |> Enum.map(fn {:ok, time} ->
        time
      end)

    total_time = Enum.sum(data)
    average_time = total_time / total_success
    longest_time = Enum.max(data)
    shortest_time = Enum.min(data)

    IO.puts("""
    Total workers: #{total_workers}
    Successfull reqs: #{total_success}
    Failed res: #{total_failures}
    Average (msec): #{average_time}
    Longest (msec): #{longest_time}
    Shortest (msec): #{shortest_time}
    """)
  end

  defp help do
    IO.puts("""
    Usage:
    blitzy -n [requests] [url]

    Options:
    -n, [--requests]      # Number of requests

    Example:
    ./blitzy -n 100 http://www.seznam.cz
    """)

    System.halt(0)
  end
end
