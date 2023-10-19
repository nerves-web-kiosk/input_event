# Changelog

## v1.4.2

* Changes
  * Don't error out when setting the repeat rate fails. This turned out to be
    hard to debug without console access.

## v1.4.1

* Changes
  * Fix phantom initial keypress events getting reported due to an issue how
    they were requested from the kernel
  * Fix lack of initial keypress reporting of high numbered key codes
  * Fix enumeration info to decode key repeat delay and period properly
  * Don't send events when enumerating. If a key was pressed when enumerating
    events, it would be incorrectly sent to the process that called
    `InputEvent.enumerate/0`.

## v1.4.0

* New features
  * Add support for setting key repeat delay and period. Thanks @doawoo.

## v1.3.0

* Changes
  * On GenServer start, send events for any keys or buttons that are already
    pressed. This fixes an issue where key presses are missed if the user
    presses them right before the GenServer starts. GenServer restarts can cause
    redundant press events now, though.

## v1.2.0

* Changes
  * Add more documenation and typespecs. The typespecs should be more useful now
    for verifying code with Dialyzer.
  * Bump minimum supported Elixir version to 1.10.

## v1.1.0

* Changes
  * Add option to grab input devices so that events don't get processed
    elsewhere (like IEx consoles). Thanks to @Xeronel for this feature.

## v1.0.0

This release only changes the version number. No code changed.

## v0.4.3

* Bug fixes
  * Fix builds on MacOS. InputEvent doesn't work on MacOS, but it will now
    compile successfully.
  * Fix a typespec so that Dialyzer runs successfully

* Improvements
  * The build process will be less verbose. If there's an error and you need the
    verbosity to debug it, run `V=1 mix compile` or `V=1 make`.

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
