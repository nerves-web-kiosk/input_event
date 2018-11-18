defmodule InputEventTest do
  use ExUnit.Case
  doctest InputEvent

  alias InputEvent.Types

  test "decodes type" do
    assert Types.decode(0, 0, 0) == {:ev_syn, :syn_report, 0}
    assert Types.decode(1, 0, 0) == {:ev_key, :key_reserved, 0}
    assert Types.decode(2, 0, 0) == {:ev_rel, :rel_x, 0}
    assert Types.decode(3, 0, 0) == {:ev_abs, :abs_x, 0}
    assert Types.decode(4, 0, 0) == {:ev_msc, :msc_serial, 0}
    assert Types.decode(5, 0, 0) == {:ev_sw, :sw_lid, 0}
    assert Types.decode(0x11, 0, 0) == {:ev_led, :led_numl, 0}
    assert Types.decode(0x12, 0, 0) == {:ev_snd, :snd_click, 0}
    assert Types.decode(0x14, 0, 0) == {:ev_rep, :rep_delay, 0}
    assert Types.decode(0x15, 0, 0) == {:ev_ff, 0, 0}
    assert Types.decode(0x16, 0, 0) == {:ev_pwr, 0, 0}
    assert Types.decode(0x17, 0, 0) == {:ev_ff_status, 0, 0}
  end

  test "decodes code" do
    assert Types.decode(0, 0, 0) == {:ev_syn, :syn_report, 0}
    assert Types.decode(1, 11, 0) == {:ev_key, :key_0, 0}
    assert Types.decode(1, 50, 0) == {:ev_key, :key_m, 0}
    assert Types.decode(3, 6, 0) == {:ev_abs, :abs_throttle, 0}
    assert Types.decode(5, 0, 0) == {:ev_sw, :sw_lid, 0}
    assert Types.decode(4, 2, 0) == {:ev_msc, :msc_gesture, 0}
    assert Types.decode(0x11, 2, 0) == {:ev_led, :led_scrolll, 0}
    assert Types.decode(0x14, 0, 0) == {:ev_rep, :rep_delay, 0}
    assert Types.decode(0x14, 1, 0) == {:ev_rep, :rep_period, 0}
    assert Types.decode(0x12, 2, 0) == {:ev_snd, :snd_tone, 0}
  end

  test "decodes" do
    assert Types.decode(0, 0, 1) == {:ev_syn, :syn_report, 1}
    assert Types.decode(1, 10, 0) == {:ev_key, :key_9, 0}
  end

  test "decodes unknown type" do
    assert Types.decode(0x50, 1, 2) == {0x50, 1, 2}
  end

  test "decodes unknown code" do
    assert Types.decode(0, 100, 2) == {:ev_syn, 100, 2}
  end

  test "decodes type by itself" do
    assert Types.decode_type(0) == :ev_syn
    assert Types.decode_type(1) == :ev_key
    assert Types.decode_type(2) == :ev_rel
    assert Types.decode_type(3) == :ev_abs
    assert Types.decode_type(4) == :ev_msc
    assert Types.decode_type(5) == :ev_sw
    assert Types.decode_type(0x11) == :ev_led
    assert Types.decode_type(0x12) == :ev_snd
    assert Types.decode_type(0x14) == :ev_rep
    assert Types.decode_type(0x15) == :ev_ff
    assert Types.decode_type(0x16) == :ev_pwr
    assert Types.decode_type(0x17) == :ev_ff_status
  end

  test "decodes code by itself" do
    assert Types.decode_code(0, 0) == :syn_report
    assert Types.decode_code(1, 11) == :key_0
    assert Types.decode_code(1, 50) == :key_m
    assert Types.decode_code(3, 6) == :abs_throttle
    assert Types.decode_code(5, 0) == :sw_lid
    assert Types.decode_code(4, 2) == :msc_gesture
    assert Types.decode_code(0x11, 2) == :led_scrolll
    assert Types.decode_code(0x14, 0) == :rep_delay
    assert Types.decode_code(0x14, 1) == :rep_period
    assert Types.decode_code(0x12, 2) == :snd_tone
  end
end
