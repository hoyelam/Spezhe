fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac bump_version

```sh
[bundle exec] fastlane mac bump_version
```

Bump marketing version (YYYY.N format). Pass version:X.X to set a specific version.

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Push a new beta build to TestFlight

### mac screenshots

```sh
[bundle exec] fastlane mac screenshots
```

Make screenshots

### mac upload_metadata_and_screenshots

```sh
[bundle exec] fastlane mac upload_metadata_and_screenshots
```

Upload Metadata

### mac upload_metadata

```sh
[bundle exec] fastlane mac upload_metadata
```

Upload Metadata Skip Screenshots

### mac dmg

```sh
[bundle exec] fastlane mac dmg
```

Build, notarize, and create DMG for direct distribution. Options: bump_marketing:true to bump marketing version

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
