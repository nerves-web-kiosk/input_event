# Changelog

## v0.4.2

* Bug fixes
  * Remove call to `sudo` and add instructions for how to read input events as a
    user the right way. Thanks to Józef Chraplewski for this fix.

## v0.4.1

* Bug fixes
  * Compile the port binary to the `_build` directory to avoid issues when
    changing mix targets

## v0.4.0

* Breaking changes
  * Enumerating input_event devices returns all device info instead of just
    the device name.

    **`< 0.4.0`**
    `{"/dev/input/eventX", "Device name"}`

    **`>= 0.4.0`**
    `{"/dev/input/eventX", %InputEvent.Info{name: "Device name"}}`

* Enhancements
  * Major refactoring and clean up in the c code. Thanks @fhunleth!
  * Added support for relative mouse events.
  * Moved input decoding to Elixir.

## v0.3.1

* Bug fixes
  * Update hex package files list.
  * Update gitignore.

## v0.3.0

* Enhancements
  * Clean up dependencies and various formatting bug fixes.

## v0.2.0

* Enhancements
  * Pushed to hex
  * Renamed project to `:input_event`
