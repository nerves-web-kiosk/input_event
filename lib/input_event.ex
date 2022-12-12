defmodule InputEvent do
  @moduledoc """
  Elixir interface to Linux input event devices
  """

  use GenServer
  alias InputEvent.{Info, Report}

  @input_event_report 1
  @input_event_version 2
  @input_event_name 3
  @input_event_id 4
  @input_event_report_info 5
  @input_event_ready 6

  @doc """
  Start a GenServer that reports events from the specified input event device
  """
  @spec start_link(Path.t() | keyword()) :: GenServer.on_start()
  def start_link(path) when is_binary(path) do
    start_link(path: path)
  end

  def start_link(init_args) when is_list(init_args) do
    init_args[:path] || raise ArgumentError, "InputEvent requires a input event device path"
    updated_args = Keyword.put_new(init_args, :grab, false)
    GenServer.start_link(__MODULE__, [updated_args[:path], self(), updated_args[:grab]])
  end

  @doc """
  Return information about this input event device
  """
  @spec info(GenServer.server()) :: Info.t()
  def info(server) do
    GenServer.call(server, :info)
  end

  @doc """
  Stop the InputEvent GenServer.
  """
  @spec stop(GenServer.server()) :: :ok
  def stop(server) do
    GenServer.stop(server)
  end

  @doc """
  Scan the system for input devices and return information on each one.
  """
  @spec enumerate() :: [{String.t(), Info.t()}]
  defdelegate enumerate(), to: InputEvent.Enumerate

  @impl GenServer
  def init([path, caller, grab]) do
    executable = :code.priv_dir(:input_event) ++ '/input_event'

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, [path, grab]},
        {:packet, 2},
        :use_stdio,
        :binary,
        :exit_status
      ])

    state = %{port: port, path: path, info: %Info{}, callback: caller, ready: false, deferred: []}

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:info, _from, %{ready: true} = state) do
    {:reply, state.info, state}
  end

  def handle_call(:info, from, state) do
    {:noreply, %{state | deferred: [from | state.deferred]}}
  end

  @impl GenServer
  def handle_info({_port, {:data, data}}, state) do
    new_state = process_notification(state, data)
    {:noreply, new_state}
  end

  def handle_info({_port, {:exit_status, _rc}}, state) do
    send(state.callback, {:input_event, state.path, :disconnect})
    {:stop, :port_crashed, state}
  end

  def handle_info(other, state) do
    IO.puts("Not expecting: #{inspect(other)}")
    send(state.callback, {:input_event, state.path, :error})
    {:stop, :error, state}
  end

  defp process_notification(state, <<@input_event_report, _sub, raw_events::binary>>) do
    Enum.each(Report.decode(raw_events), fn events ->
      send(state.callback, {:input_event, state.path, events})
    end)

    state
  end

  defp process_notification(state, <<@input_event_version, _sub, version::binary>>) do
    new_info = %{state.info | input_event_version: version}
    %{state | info: new_info}
  end

  defp process_notification(state, <<@input_event_name, _sub, name::binary>>) do
    new_info = %{state.info | name: name}
    %{state | info: new_info}
  end

  defp process_notification(
         state,
         <<@input_event_id, _sub, bus::native-16, vendor::native-16, product::native-16,
           version::native-16>>
       ) do
    new_info = %{state.info | bus: bus, vendor: vendor, product: product, version: version}
    %{state | info: new_info}
  end

  defp process_notification(state, <<@input_event_report_info, type, raw_report_info::binary>>) do
    old_report_info = state.info.report_info
    report_info = Info.decode_report_info(type, raw_report_info)
    new_info = %{state.info | report_info: [report_info | old_report_info]}
    %{state | info: new_info}
  end

  defp process_notification(state, <<@input_event_ready, _sub>>) do
    Enum.each(state.deferred, fn client -> GenServer.reply(client, state.info) end)
    %{state | ready: true, deferred: []}
  end
end
