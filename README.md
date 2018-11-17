# InputEvent

[![Hex version](https://img.shields.io/hexpm/v/input_event.svg "Hex version")](https://hex.pm/packages/input_event)

Elixir interface to Linux input event devices

## Usage

InputEvent can be used to monitor `/dev/input/event*` devices and report decoded data to
the parent process.

Start by looking for the device you want to monitor.

```elixir
iex> InputEvent.enumerate
[
  {"/dev/input/event9", "Intel Virtual Button driver"},
  {"/dev/input/event8", "Intel HID 5 button array"},
  {"/dev/input/event7", "Intel HID events"},
  {"/dev/input/event6", "SynPS/2 Synaptics TouchPad"},
  {"/dev/input/event5", "Video Bus"},
  {"/dev/input/event4", "AT Translated Set 2 keyboard"},
  {"/dev/input/event3", "Power Button"},
  {"/dev/input/event2", "Sleep Button"},
  {"/dev/input/event19", "HDA Intel PCH HDMI/DP,pcm=10"},
  {"/dev/input/event18", "HDA Intel PCH HDMI/DP,pcm=9"},
  {"/dev/input/event17", "HDA Intel PCH HDMI/DP,pcm=8"},
  {"/dev/input/event16", "HDA Intel PCH HDMI/DP,pcm=7"},
  {"/dev/input/event15", "HDA Intel PCH HDMI/DP,pcm=3"},
  {"/dev/input/event14", "HDA Intel PCH Headphone Mic"},
  {"/dev/input/event13", "DLL082A:01 06CB:76AF Touchpad"},
  {"/dev/input/event12", "Integrated_Webcam_HD: Integrate"},
  {"/dev/input/event11", "ELAN Touchscreen"},
  {"/dev/input/event10", "Dell WMI hotkeys"},
  {"/dev/input/event1", "Power Button"},
  {"/dev/input/event0", "Lid Switch"}
]
```

There's a touchscreen at `/dev/input/event11`, so let's open it:

```elixir
iex> InputEvent.start_link "/dev/input/event11"
{:ok, #PID<0.197.0>}
```

Touch the screen to test

```elixir
iex> flush
{:input_event, "/dev/input/event11",
 [
   {:ev_abs, :abs_mt_tracking_id, 1},
   {:ev_abs, :abs_mt_position_x, 2630},
   {:ev_abs, :abs_mt_position_y, 1141},
   {:ev_abs, :abs_mt_tool_x, 2630},
   {:ev_abs, :abs_mt_tool_y, 1141},
   {:ev_abs, :abs_mt_touch_major, 7},
   {:ev_abs, :abs_mt_touch_minor, 4},
   {:ev_key, :btn_touch, 1},
   {:ev_abs, :abs_x, 2630},
   {:ev_abs, :abs_y, 1141}
 ]}
{:input_event, "/dev/input/event11",
 [{:ev_abs, :abs_mt_touch_major, 8}, {:ev_abs, :abs_mt_touch_minor, 5}]}
{:input_event, "/dev/input/event11", [{:ev_abs, :abs_mt_touch_major, 9}]}
{:input_event, "/dev/input/event11", [{:ev_abs, :abs_mt_touch_major, 8}]}
{:input_event, "/dev/input/event11",
 [{:ev_abs, :abs_mt_touch_major, 7}, {:ev_abs, :abs_mt_touch_minor, 4}]}
{:input_event, "/dev/input/event11",
 [{:ev_abs, :abs_mt_touch_major, 5}, {:ev_abs, :abs_mt_touch_minor, 3}]}
{:input_event, "/dev/input/event11",
 [{:ev_abs, :abs_mt_tracking_id, -1}, {:ev_key, :btn_touch, 0}]}
:ok
```
