fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios gen

```sh
[bundle exec] fastlane ios gen
```

Regenerate the Xcode project

### ios sync_signing

```sh
[bundle exec] fastlane ios sync_signing
```

Fetch signing assets (readonly)

### ios bootstrap_signing

```sh
[bundle exec] fastlane ios bootstrap_signing
```

Create/rotate signing assets (trusted machine, write token)

### ios build

```sh
[bundle exec] fastlane ios build
```

Build a signed App Store archive

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Submit to App Store

### ios add_device

```sh
[bundle exec] fastlane ios add_device
```

Register a device and refresh the dev profile

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
