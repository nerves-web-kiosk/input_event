defmodule InputEvent do
  @moduledoc """
  Elixir interface to Linux input event devices
  """
  use GenServer

  alias InputEvent.Info
  alias InputEvent.Report

  @typedoc "An unknown event type"
  @type type_number() :: 0..0xFFFF
  @typedoc "The type of event"
  @type type_name() ::
          :ev_syn
          | :ev_key
          | :ev_rel
          | :ev_abs
          | :ev_msc
          | :ev_sw
          | :ev_led
          | :ev_snd
          | :ev_rep
          | :ev_ff
          | :ev_pwr
          | :ev_ff_status

  @typedoc """
  Event type

  Usually these are translated to an atom that corresponds with the Linux event type.
  """
  @type type() :: type_name() | type_number()

  @type code_number() :: 0..0xFFFF

  @typedoc """
  Event code

  Usually these are translated to an atom that corresponds with the Linux event code.
  Event codes depend on the event type.
  """
  @type code() :: atom() | code_number()

  @typedoc """
  Event value

  See the event type and code for how to interpret the value. For example, it could be a
  0 or 1 signifying a key press or release, or it could be an x or y coordinate or delta.
  """
  @type value() :: integer()

  @input_event_report 1
  @input_event_version 2
  @input_event_name 3
  @input_event_id 4
  @input_event_report_info 5
  @input_event_ready 6

  @typedoc """
  Options for the InputEvent Genserver
  """
  @type options() :: [path: String.t(), grab: boolean(), receiver: pid() | atom()]

  @doc """
  Start a GenServer that reports events from the specified input event device

  Options:
  * `:path` - the path to the input event device (e.g., `"/dev/input/event0"`)
  * `:grab` - set to true to prevent events from being passed to other applications (defaults to `false`)
  * `:receiver` - the pid or name of the process that receives events (defaults to the process that calls `start_link/1`

  Note that passing the device path rather than a keyword list to `start_link/1` is deprecated.
  """
  @spec start_link(String.t() | options()) :: GenServer.on_start()
  def start_link(path) when is_binary(path) do
    start_link(path: path)
  end

  def start_link(options) when is_list(options) do
    options[:path] || raise ArgumentError, "InputEvent requires a input event device path"
    updated_options = Keyword.put_new(options, :receiver, self())
    GenServer.start_link(__MODULE__, updated_options)
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
  def init(init_args) do
    executable = :code.priv_dir(:input_event) ++ ~c"/input_event"

    path = Keyword.fetch!(init_args, :path)
    grab = Keyword.get(init_args, :grab, false)
    receiver = Keyword.fetch!(init_args, :receiver)

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, [path, grab]},
        {:packet, 2},
        :use_stdio,
        :binary,
        :exit_status
      ])

    state = %{
      port: port,
      path: path,
      info: %Info{},
      callback: receiver,
      ready: false,
      deferred: []
    }

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
