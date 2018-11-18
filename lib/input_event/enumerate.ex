defmodule InputEvent.Enumerate do
  @doc """
  Return the paths to all device files
  """
  @spec all_devices() :: [Path.t()]
  def all_devices() do
    Path.wildcard("/dev/input/event*")
  end

  @doc """
  Enumerate all input event devices
  """
  @spec enumerate() :: [{String.t(), Info.t()}]
  def enumerate() do
    all_devices()
    |> Enum.map(&get_info/1)
  end

  defp get_info(path) do
    {:ok, server} = InputEvent.start_link(path)
    info = InputEvent.info(server)
    InputEvent.stop(server)
    {path, info}
  end
end
