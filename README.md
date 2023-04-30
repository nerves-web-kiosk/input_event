# InputEvent

[![Hex version](https://img.shields.io/hexpm/v/input_event.svg "Hex version")](https://hex.pm/packages/input_event)
[![API docs](https://img.shields.io/hexpm/v/input_event.svg?label=hexdocs "API docs")](https://hexdocs.pm/input_event)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/nerves-web-kiosk/input_event/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/nerves-web-kiosk/input_event/tree/main)

Elixir interface to Linux input event devices. Using `input_event`, you can

* Find out what keyboards, joysticks, mice, touchscreens, etc. are connected
* Get information on what kinds of events they can produce
* Get decoded events sent to you

This library is intended for use with Nerves. If you're running a desktop Linux
distribution, this can still work, but you'll likely want to use a higher level
API for receiving events.

## Usage

InputEvent can be used to monitor `/dev/input/event*` devices and report decoded
data to the parent process.

Start by looking for the device you want to monitor:

```elixir
iex> InputEvent.enumerate
[
  {"/dev/input/event0",
   %InputEvent.Info{
     bus: 0,
     input_event_version: "1.0.1",
     name: "FT5406 memory based driver",
     product: 0,
     report_info: [
       ev_abs: [
         abs_x: %{flat: 0, fuzz: 0, max: 800, min: 0, resolution: 0, value: 0},
         abs_y: %{flat: 0, fuzz: 0, max: 480, min: 0, resolution: 0, value: 0},
         abs_mt_slot: %{
           flat: 0,
           fuzz: 0,
           max: 9,
           min: 0,
           resolution: 0,
           value: 0
         },
         abs_mt_position_x: %{
           flat: 0,
           fuzz: 0,
           max: 800,
           min: 0,
           resolution: 0,
           value: 0
         },
         abs_mt_position_y: %{
           flat: 0,
           fuzz: 0,
           max: 480,
           min: 0,
           resolution: 0,
           value: 0
         },
         abs_mt_tracking_id: %{
           flat: 0,
           fuzz: 0,
           max: 65535,
           min: 0,
           resolution: 0,
           value: 0
         }
       ],
       ev_key: [:btn_touch]
     ],
     vendor: 0,
     version: 0
   }}
]
```

There's a touchscreen at `/dev/input/event0`, so let's open it:

```elixir
iex> InputEvent.start_link("/dev/input/event0")
{:ok, #PID<0.197.0>}
```

Touch the screen to test

```elixir
iex> flush
{:input_event, "/dev/input/event0",
 [
   {:ev_abs, :abs_mt_tracking_id, 1},
   {:ev_abs, :abs_mt_position_x, 350},
   {:ev_abs, :abs_mt_position_y, 119},
   {:ev_key, :btn_touch, 1},
   {:ev_abs, :abs_x, 350},
   {:ev_abs, :abs_y, 119}
 ]}
{:input_event, "/dev/input/event0",
 [
   {:ev_abs, :abs_mt_position_x, 352},
   {:ev_abs, :abs_mt_position_y, 122},
   {:ev_abs, :abs_x, 352},
   {:ev_abs, :abs_y, 122}
 ]}
{:input_event, "/dev/input/event0",
 [{:ev_abs, :abs_mt_tracking_id, -1}, {:ev_key, :btn_touch, 0}]}
{:input_event, "/dev/input/event0",
 [
   {:ev_abs, :abs_mt_tracking_id, 2},
   {:ev_abs, :abs_mt_position_x, 361},
   {:ev_abs, :abs_mt_position_y, 361},
   {:ev_abs, :abs_mt_slot, 1},
   {:ev_abs, :abs_mt_tracking_id, 3},
   {:ev_abs, :abs_mt_position_x, 425},
   {:ev_abs, :abs_mt_position_y, 139},
   {:ev_key, :btn_touch, 1},
   {:ev_abs, :abs_x, 361},
   {:ev_abs, :abs_y, 361}
 ]}
{:input_event, "/dev/input/event0", [{:ev_abs, :abs_mt_position_y, 142}]}
{:input_event, "/dev/input/event0",
 [
   {:ev_abs, :abs_mt_slot, 0},
   {:ev_abs, :abs_mt_position_y, 363},
   {:ev_abs, :abs_mt_slot, 1},
   {:ev_abs, :abs_mt_position_x, 427},
   {:ev_abs, :abs_mt_position_y, 147},
   {:ev_abs, :abs_y, 363}
 ]}
{:input_event, "/dev/input/event0",
 [{:ev_abs, :abs_mt_position_x, 428}, {:ev_abs, :abs_mt_position_y, 149}]}
{:input_event, "/dev/input/event0",
 [
   {:ev_abs, :abs_mt_slot, 0},
   {:ev_abs, :abs_mt_tracking_id, -1},
   {:ev_abs, :abs_mt_slot, 1},
   {:ev_abs, :abs_mt_tracking_id, -1},
   {:ev_key, :btn_touch, 0}
 ]}
:ok
```

## Examples

Enumerating attached devices can be really helpful in figuring out what kind of
messages that you'll be sent. Here are other examples:

### Keyboard

```elixir
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
       ev_abs: [
         abs_volume: %{
           flat: 0,
           fuzz: 0,
           max: 652,
           min: 1,
           resolution: 0,
           value: 0
         }
       ],
       ev_rel: [:rel_hwheel],
       ev_key: [:key_esc, :key_1, :key_2, :key_3, :key_4, :key_5, :key_6,
        :key_7, :key_8, :key_9, :key_0, :key_minus, :key_equal, :key_backspace,
        :key_tab, :key_q, :key_w, :key_e, :key_r, :key_t, :key_y, :key_u,
        :key_i, :key_o, :key_p, :key_leftbrace, :key_rightbrace, ...]
     ],
     vendor: 1133,
     version: 273
   }}
```

Events from a keyboard look like:

```elixir
{:input_event, "/dev/input/event3",
 [{:ev_msc, :msc_scan, 458761}, {:ev_key, :key_f, 1}]}
{:input_event, "/dev/input/event3",
 [{:ev_msc, :msc_scan, 458761}, {:ev_key, :key_f, 0}]}
```

The 1 and 0 indicate key down and key up.

### Mouse

```elixir
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
   }}
```

Events from a mouse look like:

```elixir
{:input_event, "/dev/input/event2", [{:ev_rel, :rel_x, 12}]}
{:input_event, "/dev/input/event2",
 [{:ev_rel, :rel_x, 14}, {:ev_rel, :rel_y, -1}]}
```

Notice that if there's no movement in an axis that you won't get an update for that axis.

### Joystick

```elixir
  {"/dev/input/event15",
   %InputEvent.Info{
     bus: 3,
     input_event_version: "1.0.1",
     name: "Microsoft X-Box 360 pad",
     product: 654,
     report_info: [
       ev_ff: 'PQXYZ`',
       ev_abs: [
         abs_x: %{
           flat: 128,
           fuzz: 16,
           max: 32767,
           min: -32768,
           resolution: 0,
           value: 0
         },
         abs_y: %{
           flat: 128,
           fuzz: 16,
           max: 32767,
           min: -32768,
           resolution: 0,
           value: 0
         },
         abs_z: %{flat: 0, fuzz: 0, max: 255, min: 0, resolution: 0, value: 0},
         abs_rx: %{
           flat: 128,
           fuzz: 16,
           max: 32767,
           min: -32768,
           resolution: 0,
           value: 0
         },
         abs_ry: %{
           flat: 128,
           fuzz: 16,
           max: 32767,
           min: -32768,
           resolution: 0,
           value: 0
         },
         abs_rz: %{flat: 0, fuzz: 0, max: 255, min: 0, resolution: 0, value: 0},
         abs_hat0x: %{
           flat: 0,
           fuzz: 0,
           max: 1,
           min: -1,
           resolution: 0,
           value: 0
         },
         abs_hat0y: %{
           flat: 0,
           fuzz: 0,
           max: 1,
           min: -1,
           resolution: 0,
           value: 0
         }
       ],
       ev_key: [:btn_a, :btn_b, :btn_x, :btn_y, :btn_tl, :btn_tr, :btn_select,
        :btn_start, :btn_mode, :btn_thumbl, :btn_thumbr]
     ],
     vendor: 1118,
     version: 272
   }}
```

### Power button

```elixir
  {"/dev/input/event0",
   %InputEvent.Info{
     bus: 25,
     input_event_version: "1.0.1",
     name: "Power Button",
     product: 1,
     report_info: [ev_key: [:key_power]],
     vendor: 0,
     version: 0
   }}
```

The power button input device works just like a one-button keyboard.

## Grab device

Devices can be grabbed to prevent output into other applications.

```elixir
iex> InputEvent.start_link(path: "/dev/input/event0", grab: true)
{:ok, #PID<0.197.0>}
```

### Permissions

To be able to read from `/dev/input/event*` you need to add user to the `input`
group:

```sh
sudo usermod -a -G input <username>
```

And restart user session.
