defmodule InputEventTest do
  use ExUnit.Case
  doctest InputEvent

  alias InputEvent.Decoder

  test "decode type" do
    assert Decoder.decode_type(0) == :ev_syn
    assert Decoder.decode_type(1) == :ev_key
    assert Decoder.decode_type(2) == :ev_rel
    assert Decoder.decode_type(3) == :ev_abs
    assert Decoder.decode_type(4) == :ev_msc
    assert Decoder.decode_type(5) == :ev_sw
    assert Decoder.decode_type(0x11) == :ev_led
    assert Decoder.decode_type(0x12) == :ev_snd
    assert Decoder.decode_type(0x14) == :ev_rep
    assert Decoder.decode_type(0x15) == :ev_ff
    assert Decoder.decode_type(0x16) == :ev_pwr
    assert Decoder.decode_type(0x17) == :ev_ff_status
  end

  test "decode code" do
    assert Decoder.decode_code(:ev_syn, 0) == :syn_report
    assert Decoder.decode_code(:ev_key, 11) == :key_0
    assert Decoder.decode_code(:ev_key, 50) == :key_m
    assert Decoder.decode_code(:ev_abs, 6) == :abs_throttle
    assert Decoder.decode_code(:ev_sw, 0) == :sw_lid
    assert Decoder.decode_code(:ev_msc, 2) == :msc_gesture
    assert Decoder.decode_code(:ev_led, 2) == :led_scrolll
    assert Decoder.decode_code(:ev_rep, 0) == :rep_delay
    assert Decoder.decode_code(:ev_rep, 1) == :rep_period
    assert Decoder.decode_code(:ev_snd, 2) == :snd_tone
  end

  test "decode" do
    assert Decoder.decode(0, 0, 1) == {:ev_syn, :syn_report, 1}
    assert Decoder.decode(1, 10, 0) == {:ev_key, :key_9, 0}
  end

  #test "decode unknown type" do
  #  assert Decoder.decode_type(0x50) == nil
  #end

  test "decode unknown code" do
    assert Decoder.decode_code(:bogus, 100) == 100
  end
end
