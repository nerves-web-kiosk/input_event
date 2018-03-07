defmodule InputEvent do
  use GenServer
  import InputEvent.Decoder

  def start_link(fd) do
    GenServer.start_link(__MODULE__, [fd, self()])
  end

  @doc """
  Stop the UART GenServer.
  """
  def stop(pid) do
    GenServer.stop(pid)
  end

  def enumerate() do
    executable = :code.priv_dir(:input_event) ++ '/input_event'

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, ["enumerate"]},
        {:packet, 2},
        :use_stdio,
        :binary
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

  def init([fd, caller]) do
    executable = :code.priv_dir(:input_event) ++ '/input_event'

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, [fd]},
        {:packet, 2},
        :use_stdio,
        :binary,
        :exit_status
      ])

    state = %{port: port, name: fd, callback: caller, buffer: []}

    {:ok, state}
  end

  def handle_info({_, {:data, <<?n, message::binary>>}}, state) do
    msg = :erlang.binary_to_term(message)
    handle_port(msg, state)
  end

  def handle_info({_, {:data, <<?e, message::binary>>}}, state) do
    error = :erlang.binary_to_term(message)
    send(state.callback, {:input_event, state.name, error})
    {:stop, error, state}
  end

  defp handle_port({:event, type, code, value}, state) do
    state =
      case decode(type, code, value) do
        {:ev_syn, :syn_report, 0} ->
          if state.callback do
            send(state.callback, {:input_event, state.name, Enum.reverse(state.buffer)})
          end

          %{state | buffer: []}

        event ->
          %{state | buffer: [event | state.buffer]}
      end

    {:noreply, state}
  end
end
