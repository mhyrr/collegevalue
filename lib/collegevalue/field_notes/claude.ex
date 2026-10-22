defmodule Collegevalue.FieldNotes.Claude do
  @moduledoc """
  One bounded `claude --print` call. Dev-time only: the field notes runner
  uses it, the web app never does.

  The call gets only the tools named, no MCP servers, no skills and no HIVE
  identity, a dollar cap (`--max-budget-usd`) and a deadline enforced here,
  since macOS ships no `timeout`. The reply is the CLI's JSON envelope; an
  error envelope is an error, never data.
  """

  @system "You are a careful research assistant. Follow the user's instructions exactly and reply in the format they ask for."

  @doc """
  Runs `prompt`. Options: `:model`, `:tools` (a list, `[]` for none),
  `:budget_usd`, `:timeout_ms`. Returns `{:ok, %{text: text, cost_usd: cost}}`
  or `{:error, reason}`.
  """
  def run(prompt, opts) do
    tools = Keyword.get(opts, :tools, [])

    args =
      ["-p", prompt, "--output-format", "json", "--model", Keyword.fetch!(opts, :model),
       "--system-prompt", @system, "--strict-mcp-config", "--disable-slash-commands",
       "--max-budget-usd", to_string(Keyword.fetch!(opts, :budget_usd)),
       "--tools", Enum.join(tools, ",")] ++
        if(tools == [], do: [], else: ["--allowedTools", Enum.join(tools, ",")])

    case System.find_executable("claude") do
      nil -> {:error, "claude is not on PATH"}
      exe -> exe |> spawn(args) |> collect(Keyword.get(opts, :timeout_ms, 600_000)) |> decode()
    end
  end

  # Through sh, so stdin is /dev/null: otherwise the CLI waits 3s for piped input.
  defp spawn(exe, args) do
    Port.open({:spawn_executable, "/bin/sh"}, [
      :binary,
      :exit_status,
      :hide,
      args: ["-c", ~s(exec "$0" "$@" < /dev/null), exe | args],
      # The HIVE SessionStart hook stays quiet when this is set.
      env: [{~c"HIVE_IDENTITY_IN_PROMPT", ~c"1"}]
    ])
  end

  defp collect(port, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    collect(port, deadline, [])
  end

  defp collect(port, deadline, acc) do
    remaining = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, data}} -> collect(port, deadline, [acc, data])
      {^port, {:exit_status, 0}} -> {:ok, IO.iodata_to_binary(acc)}
      {^port, {:exit_status, status}} -> {:error, "claude exited #{status}: #{String.slice(IO.iodata_to_binary(acc), 0, 500)}"}
    after
      remaining ->
        with {:os_pid, pid} <- Port.info(port, :os_pid), do: System.cmd("kill", ["-9", to_string(pid)])
        Port.close(port)
        {:error, "claude ran past its deadline and was killed"}
    end
  end

  defp decode({:error, _reason} = error), do: error

  defp decode({:ok, output}) do
    case Jason.decode(output) do
      {:ok, %{"is_error" => false, "result" => text} = envelope} ->
        {:ok, %{text: text, cost_usd: envelope["total_cost_usd"] || 0}}

      {:ok, envelope} ->
        {:error, "claude returned an error: #{String.slice(inspect(envelope["result"] || envelope), 0, 500)}"}

      {:error, _} ->
        {:error, "claude's output isn't JSON: #{String.slice(output, 0, 500)}"}
    end
  end
end
