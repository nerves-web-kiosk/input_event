defmodule InputEvent.Info do
  defstruct input_event_version: "",
            name: "",
            bus: 0,
            vendor: 0,
            product: 0,
            version: 0,
            report_info: []

  @type t :: %__MODULE__{
          input_event_version: String.t(),
          name: String.t(),
          bus: non_neg_integer(),
          vendor: non_neg_integer(),
          product: non_neg_integer(),
          version: non_neg_integer(),
          report_info: [{atom(), [any()]}]
        }

  @doc """
  Helper function for decoding raw report information from the port driver.
  """
  def decode_report_info(raw_type, raw_report_info) do
    type = InputEvent.Types.decode_type(raw_type)

    {type, decode_codes(raw_type, raw_report_info)}
  end

  defp decode_codes(0x03, raw_report_info) do
    for <<code::native-16, value::native-32, min::native-32, max::native-32, fuzz::native-32,
          flat::native-32, resolution::native-32 <- raw_report_info>> do
      {InputEvent.Types.decode_code(0x03, code), value, min, max, fuzz, flat, resolution}
    end
  end

  defp decode_codes(raw_type, raw_report_info) do
    for <<code::native-16 <- raw_report_info>> do
      InputEvent.Types.decode_code(raw_type, code)
    end
  end
end
