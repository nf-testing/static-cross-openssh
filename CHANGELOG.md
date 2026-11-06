# Changelog
<!-- markdownlint-disable MD024 -->

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For versions that have a major of 0, a convention is followed so that
the minor number is incremented when backward-incompatible changes are
made, while the third number is incremented for backward compatible
changes. For example, versions `0.2.x` are not compatible with `0.1.x`.

## [Unreleased]

There are no unreleased changes at this time.

## [0.2.8-nf] - 2026-11-06

### Changed

* OpenSSH portable source code archives are now retrieved directly from
  OpenBSD's CDN rather than from the GitHub mirror's archives.
* The GPG keys of the maintainers will now be retrieved and imported
  (meaning `gnupg` is also a new dependency), along with the detached
  signature file (`.asc`) at the time of the download. We now will verify
  that signature's validity before extraction, failing if it does not pass.
* Added some error handling on the archive download `curl` commands and on
  the `tar` extraction one, hopefully making future step failures clearer.
* Default versions bumped to the latest non-feature ones for all packages:
  * OpenSSH moved from `9.9p2` to `10.6p2` to include the fixes for [the
    `*sshole` bug](https://sshhole.com).
  * OpenSSL moved from `3.5.0` to `4.0.3` to include fixes for several CVEs.
  * zlib moved from `1.3.1` to `1.4` to include security fixes, including
    suggestions from a security review and patches for multiple CVEs.
* Default config flags were updated to include `--disable-wtmp` and
  `--disable-wtmpx`
* Removed `unzip` dependency by switching zlib package retrieval to use the
  `.tar.gz` archive format.
* Added a warning to the README to ensure anyone looking for the original
  finds it rather than using our fork.
* The build validates the versions of OpenSSH, OpenSSL, and zlib. An
  invalid version stops make with an error that shows the expected format.
  Before this change, an invalid OpenSSH version became a wrong value, for
  example `10.2` became `10.2p10.2`.
* The latest OpenSSH version now comes from the OpenBSD mirror listing, not
  from the GitHub tags. The GitHub mirror can lag behind. For example, it
  has no `V_10_6_P2` tag, so the latest version was `10.6p1`.
* The latest OpenSSL version now includes OpenSSL 4.x and later. Before this
  change, only 3.x tags were included, so `__all__/VERSION=latest` selected
  `3.6.5`. Beta releases are now also excluded.
* Version sorting now uses `sort -V`. The old sort compared the first field
  as text, so `9.9p2` came after `10.6p2`.
* OpenSSL versions before 3.0.0 are rejected. The download URL does not
  support their tag and archive names.

---

Original upstream changelog follows:

## [0.2.8] - 2026-05-24

### Added

* Sign commits and enable verification in the build pipeline.
* Add signed digest files for releases.
* Add verification instructions in the docs.

## [0.2.7] - 2026-03-15

### Changed

* Moved to Codeberg.

## [0.2.6] - 2025-12-14

### Changed

* Grab `zlib` sources from GH rather than from zlib.net. We check GH for
  tags in order to discover versions, but not all tags have a tarball at
  zlib.net. Since GH serves zip files, this implies the `unzip` tool is
  now required to build.

## [0.2.5] - 2025-11-22

### Added

* Also copy `sshd-auth` for OpenSSH 10+.

### Fixed

* Fix latest versions of OpenSSH (10+) and the toolchain (2025+) not
  being listed when asking for latest versions.

## [0.2.4] - 2025-05-01

### Changed

* Binaries are now built weekly.
* Use Ubuntu 24.04 for CI actions.
* Update package versions

## [0.2.3] - 2024-09-28

### Changed

* Binaries are now hosted on GitHub as artifacts.

## [0.2.2] - 2024-09-15

### Fixed

* The download URL of OpenSSL source tarballs has been updated. The old
  one no longer works.

## [0.2.1] - 2024-08-15

### Added

* A new tunable `SHRINK` controls the ability to create smaller builds,
  trading some non-essential features or runtime performance for much
  smaller files.

## [0.2.0] - 2024-07-14

### Changed

* Many things: it's major rewrite. Here's a few.
* Updated default package versions.
* Before building, a configuration file must be produced by using `make
  config` or by copying an existing one.
* It is no longer necessary to delete the toolchain to switch to a
  different architecture.
* Better directory tree organization to support multi-architecture.

### Added

* Side-by-side multi-architecture support. You can build for an
  architecture without deleting the toolchains or artifacts for others.
* Real dependency tracking among package versions: if a package version
  is changed in the configuration file, it is not necessary to rebuild
  everything: only that package and its dependant will be rebuilt.
  Changing the toolchain forces a full rebuild. Changes to the prefix
  are currently not tracked.
* Configuration files are copied alongside binaries so that they work as
  a "bill of material" of sources used for the build. They can be used
  to remake that exact build.

## [0.1.4] - 2023-10-06

### Added

* Implemented a mechanism to control versions of packages and the
  toolchain without editing the makefiles. It is also possible to use
  the latest versions for all components. Note that, for OpenSSL, the
  _latest_ version means 3.x, while the default version in the makefile
  has been kept to 1.x for now.

## [0.1.3] - 2023-08-11

### Changed

* Updated openssl to 1.1.1v
* Updated openssh to 9.4

## [0.1.2] - 2023-06-15

### Changed

* Updated zlib to 1.2.13
* Updated openssl to 1.1.1u
* Updated openssh to 9.3

## [0.1.1] - 2022-08-16

### Fixed

* Quote expansions of `$(MAKE)` in recipes.
* Properly place `+` markers on the first recipe line when using
  `.ONESHELL`.

## [0.1.0] - 2022-08-11

### Added

* Initial release.

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
