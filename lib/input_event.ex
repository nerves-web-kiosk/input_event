defmodule InputEvent do
  use GenServer
  alias InputEvent.Decoder

  @moduledoc """
  Elixir interface to Linux input event devices
  """

  @input_event 1

  @doc """
  Start a GenServer that reports events from the specified input event device
  """
  @spec start_link(Path.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(input_event_path) do
    GenServer.start_link(__MODULE__, [input_event_path, self()])
  end

  @doc """
  Stop the InputEvent GenServer.
  """
  def stop(pid) do
    GenServer.stop(pid)
  end

  @spec enumerate() :: [{String.t(), String.t()}]
  def enumerate() do
    executable = :code.priv_dir(:input_event) ++ '/input_event'

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, ["enumerate"]},
        {:packet, 2},
        :use_stdio,
        :binary,
        :exit_status
      ])

    receive do
      {^port, {:data, <<?r, message::binary>>}} ->
        :erlang.binary_to_term(message)
    after
      5_000 ->
        Port.close(port)
        []
    end
  end

  def init([input_event_path, caller]) do
    executable = :code.priv_dir(:input_event) ++ '/input_event'

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, [input_event_path]},
        {:packet, 2},
        :use_stdio,
        :binary,
        :exit_status
      ])

    state = %{port: port, input_event_path: input_event_path, callback: caller}

    {:ok, state}
  end

  def handle_info({_port, {:data, data}}, state) do
    process_notification(state, data)
    {:noreply, state}
  end

  def handle_info({_port, {:exit_status, _rc}}, state) do
    send(state.callback, {:input_event, state.input_event_path, :disconnect})
    {:stop, :normal, state}
  end

  def handle_info(other, state) do
    IO.puts("Not expecting: #{inspect(other)}")
    send(state.callback, {:input_event, state.input_event_path, :error})
    {:stop, :error, state}
  end

  defp process_notification(state, <<@input_event, _fd, raw_events::binary>>) do
    decode_input_events(raw_events, [], [])
    |> Enum.reverse()
    |> Enum.each(fn events ->
      send(state.callback, {:input_event, state.input_event_path, events})
    end)
  end

  defp decode_input_events(<<>>, [], all_events), do: all_events

  defp decode_input_events(<<>>, _leftovers, all_events) do
    # Dropping unterminated events #{inspect(leftovers)}. The kernel shouldn't do this.
    # NOTE: consider crashing.
    all_events
  end

  defp decode_input_events(
         <<type::unsigned-native-16, code::unsigned-native-16, value::signed-native-32,
           rest::binary>>,
         events,
         all_events
       ) do
    case Decoder.decode(type, code, value) do
      {:ev_syn, :syn_report, _ignore} ->
        decode_input_events(rest, [], [Enum.reverse(events) | all_events])

      event ->
        decode_input_events(rest, [event | events], all_events)
    end
  end
end
