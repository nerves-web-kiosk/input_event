defmodule InputEvent.InfoTest do
  use ExUnit.Case

  alias InputEvent.Info

  test "decodes code list" do
    assert Info.decode_report_info(1, <<2::native-16, 3::native-16>>) ==
             {:ev_key, [:key_1, :key_2]}
  end

  test "decodes abs code list" do
    assert Info.decode_report_info(
             3,
             <<0x20::native-16, 1::native-32, 2::native-32, 3::native-32, 4::native-32,
               5::native-32, 6::native-32>>
           ) == {:ev_abs, [{:abs_volume, 1, 2, 3, 4, 5, 6}]}
  end
end
