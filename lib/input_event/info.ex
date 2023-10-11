defmodule InputEvent.Info do
  @moduledoc """
  Information about a input event file
  """

  defstruct input_event_version: "",
            name: "",
            bus: 0,
            vendor: 0,
            product: 0,
            version: 0,
            report_info: []

  @type t() :: %__MODULE__{
          input_event_version: String.t(),
          name: String.t(),
          bus: non_neg_integer(),
          vendor: non_neg_integer(),
          product: non_neg_integer(),
          version: non_neg_integer(),
          report_info: [{atom(), [any()]}]
        }

  @type report_info() :: {InputEvent.type(), [InputEvent.code() | {InputEvent.code(), map()}]}

  @doc """
  Helper function for decoding raw report information from the port driver.
  """
  @spec decode_report_info(InputEvent.type_number(), binary()) :: report_info()
  def decode_report_info(raw_type, raw_report_info) do
    type = InputEvent.Types.decode_type(raw_type)

    {type, decode_codes(raw_type, raw_report_info)}
  end

  defp decode_codes(0x03, raw_report_info) do
    for <<code::native-16, value::native-signed-32, min::native-signed-32, max::native-signed-32,
          fuzz::native-signed-32, flat::native-signed-32,
          resolution::native-signed-32 <- raw_report_info>> do
      {InputEvent.Types.decode_code(0x03, code),
       %{value: value, min: min, max: max, fuzz: fuzz, flat: flat, resolution: resolution}}
    end
  end

  defp decode_codes(raw_type, raw_report_info) do
    for <<code::native-16 <- raw_report_info>> do
      InputEvent.Types.decode_code(raw_type, code)
    end
  end
end
