defmodule InputEvent.Report do
  @moduledoc false

  alias InputEvent.Types

  @doc """
  Decode a report from the port

  This returns a list of event lists.
  """
  @spec decode(binary()) :: [[{atom(), atom(), integer()}]]
  def decode(report) do
    decode(report, [], [])
    |> Enum.reverse()
  end

  defp decode(<<>>, [], all_events), do: all_events

  defp decode(<<>>, _leftovers, all_events) do
    # Dropping unterminated events #{inspect(leftovers)}. The kernel shouldn't do this.
    # NOTE: consider crashing.
    all_events
  end

  defp decode(
         <<type::unsigned-native-16, code::unsigned-native-16, value::signed-native-32,
           rest::binary>>,
         events,
         all_events
       ) do
    case Types.decode(type, code, value) do
      {:ev_syn, :syn_report, _ignore} ->
        decode(rest, [], [Enum.reverse(events) | all_events])

      event ->
        decode(rest, [event | events], all_events)
    end
  end
end
