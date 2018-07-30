defmodule Blitzy.Worker do
  use Timex
  require Logger

  def start(url) do
    IO.puts("Running on #node-#{node()}")

    {timestamp, response} = Duration.measure(fn -> HTTPoison.get(url) end)
    handle_response({Duration.to_milliseconds(timestamp), response})
  end

  def start(caller_pid, url) do
    {timestamp, response} = Duration.measure(fn -> HTTPoison.get(url) end)
    response = handle_response({Duration.to_milliseconds(timestamp), response})

    send(caller_pid, {self(), response})
  end

  defp handle_response({msecs, {:ok, %HTTPoison.Response{status_code: code}}})
       when code >= 200 and code <= 304 do
    Logger.info("worker [#{node()}-#{inspect(self())}] completed in #{msecs} msecs")
    {:ok, msecs}
  end

  defp handle_response({_msecs, {:error, reason}}) do
    Logger.info("worker [#{node()}-#{inspect(self())}] error due to #{inspect(reason)}")
    {:error, reason}
  end

  defp handle_response({_msecs, _}) do
    Logger.info("worker [#{node()}-#{inspect(self())}] errored out")
    {:error, :unknown}
  end
end
