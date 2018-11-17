defmodule InputEventTest do
  use ExUnit.Case
  doctest InputEvent

  alias InputEvent.Decoder

  test "decode type" do
    assert Decoder.decode(0, 0, 0) == {:ev_syn, :syn_report, 0}
    assert Decoder.decode(1, 0, 0) == {:ev_key, :key_reserved, 0}
    assert Decoder.decode(2, 0, 0) == {:ev_rel, :rel_x, 0}
    assert Decoder.decode(3, 0, 0) == {:ev_abs, :abs_x, 0}
    assert Decoder.decode(4, 0, 0) == {:ev_msc, :msc_serial, 0}
    assert Decoder.decode(5, 0, 0) == {:ev_sw, :sw_lid, 0}
    assert Decoder.decode(0x11, 0, 0) == {:ev_led, :led_numl, 0}
    assert Decoder.decode(0x12, 0, 0) == {:ev_snd, :snd_click, 0}
    assert Decoder.decode(0x14, 0, 0) == {:ev_rep, :rep_delay, 0}
    assert Decoder.decode(0x15, 0, 0) == {:ev_ff, 0, 0}
    assert Decoder.decode(0x16, 0, 0) == {:ev_pwr, 0, 0}
    assert Decoder.decode(0x17, 0, 0) == {:ev_ff_status, 0, 0}
  end

  test "decode code" do
    assert Decoder.decode(0, 0, 0) == {:ev_syn, :syn_report, 0}
    assert Decoder.decode(1, 11, 0) == {:ev_key, :key_0, 0}
    assert Decoder.decode(1, 50, 0) == {:ev_key, :key_m, 0}
    assert Decoder.decode(3, 6, 0) == {:ev_abs, :abs_throttle, 0}
    assert Decoder.decode(5, 0, 0) == {:ev_sw, :sw_lid, 0}
    assert Decoder.decode(4, 2, 0) == {:ev_msc, :msc_gesture, 0}
    assert Decoder.decode(0x11, 2, 0) == {:ev_led, :led_scrolll, 0}
    assert Decoder.decode(0x14, 0, 0) == {:ev_rep, :rep_delay, 0}
    assert Decoder.decode(0x14, 1, 0) == {:ev_rep, :rep_period, 0}
    assert Decoder.decode(0x12, 2, 0) == {:ev_snd, :snd_tone, 0}
  end

  test "decode" do
    assert Decoder.decode(0, 0, 1) == {:ev_syn, :syn_report, 1}
    assert Decoder.decode(1, 10, 0) == {:ev_key, :key_9, 0}
  end

  test "decode unknown type" do
    assert Decoder.decode(0x50, 1, 2) == {0x50, 1, 2}
  end

  test "decode unknown code" do
    assert Decoder.decode(0, 100, 2) == {:ev_syn, 100, 2}
  end
end
