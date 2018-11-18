# InputEvent

[![Hex version](https://img.shields.io/hexpm/v/input_event.svg "Hex version")](https://hex.pm/packages/input_event)

Elixir interface to Linux input event devices. Using `input_event`, you can

* Find out what keyboards, joysticks, mice, touchscreens, etc. are connected
* Get information on what kinds of events they can produce
* Get decoded events sent to you

This library is intended for use with Nerves. If you're running a desktop Linux
distribution, this can still work, but you'll likely want to use a higher level
API to receiving events.

## Usage

InputEvent can be used to monitor `/dev/input/event*` devices and report decoded
data to the parent process.

Start by looking for the device you want to monitor.

```elixir
iex> InputEvent.enumerate
[
  {"/dev/input/event0",
   %InputEvent.Info{
     bus: 25,
     input_event_version: "1.0.1",
     name: "Power Button",
     product: 1,
     report_info: [ev_key: [:key_power]],
     vendor: 0,
     version: 0
   }},
  {"/dev/input/event2",
   %InputEvent.Info{
     bus: 3,
     input_event_version: "1.0.1",
     name: "Logitech M310",
     product: 4132,
     report_info: [
       ev_msc: [:msc_scan],
       ev_rel: [:rel_x, :rel_y, :rel_hwheel, :rel_wheel],
       ev_key: [:btn_left, :btn_right, :btn_middle, :btn_side, :btn_extra,
        :btn_forward, :btn_back, :btn_task, 280, 281, 282, 283, 284, 285, 286,
        287]
     ],
     vendor: 1133,
     version: 273
   }},
  {"/dev/input/event3",
   %InputEvent.Info{
     bus: 3,
     input_event_version: "1.0.1",
     name: "Logitech K520",
     product: 8209,
     report_info: [
       ev_rep: [250, :rep_delay, 33, :rep_delay],
       ev_led: [:led_numl, :led_capsl, :led_scrolll, :led_compose, :led_kana],
       ev_msc: [:msc_scan],
       ev_abs: [{:abs_volume, 0, 1, 652, 0, 0, 0}],
       ev_rel: [:rel_hwheel],
       ev_key: [:key_esc, :key_1, :key_2, :key_3, :key_4, :key_5, :key_6,
        :key_7, :key_8, :key_9, :key_0, :key_minus, :key_equal, :key_backspace,
        :key_tab, :key_q, :key_w, :key_e, :key_r, :key_t, :key_y, :key_u,
        :key_i, :key_o, :key_p, :key_leftbrace, :key_rightbrace, :key_enter,
        ...]
     ],
     vendor: 1133,
     version: 273
   }},
  {"/dev/input/event4",
   %InputEvent.Info{
     bus: 0,
     input_event_version: "1.0.1",
     name: "HD-Audio Generic Front Mic",
     product: 0,
     report_info: [ev_sw: [:sw_microphone_insert]],
     vendor: 0,
     version: 0
   }},
  {"/dev/input/event11",
   %InputEvent.Info{
     bus: 0,
     input_event_version: "1.0.1",
     name: "ELAN Touchscreen",
     product: 0,
     report_info: ...,
     vendor: 0,
     version: 0
  }}
]
```

There's a touchscreen at `/dev/input/event11`, so let's open it:

```elixir
iex> InputEvent.start_link("/dev/input/event11")
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
