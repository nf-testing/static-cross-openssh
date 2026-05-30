# static-cross-openssh: statically cross-compile ssh

[![Verify file integrity](https://img.shields.io/badge/%F0%9F%94%92Check%20integrity%F0%9F%94%92-blue)](#verify)
_Read how to check your download is good_

[![Get the binaries](https://img.shields.io/badge/Get%20the%20binaries-8a2be2)](https://codeberg.org/binary-manu/static-cross-openssh/releases/tag/weekly)
_Then grab it_

_Warning: if you already used this project, please skim through the docs
again, as a new major rewrite is out and some things work differently._

This project means to be an easy way to rapidly build cross-compiled,
static executables for the openssh tools. They
can then be used to get ssh access on devices such as embedded Linux
systems or Android phones, without depending on larger toolkits like
Termux. On rooted Android devices, it is easy to set up sshd to get root
access to the whole filesystem from another device using an SFTP client.

The goal here is simplicity, which takes precedence over performance and
security. It is assumed that the built services will run as root and that
will by started by the user, only when needed. It's not meant to replace
properly built SSH apps or packages, just to be a way out when you need
an SSH for some exotic device for occasional use.

## Credits due

I was looking for a way to statically build OpenSSH, and found [this
script][original-script].

It worked well, but it didn't support cross compilation. Also, it would
re-download stuff every time it was run. So I turned it into a set of
Makefiles to take advantage of its dependency tracking, then added
cross-compilation support by automatically downloading ready-made
toolchains from [bootlin][bootlin-toolchains].

Ideas for the Makefiles come from the OpenWRT build system, in a
brutally simplified form.

## Usage

### Basic

To start a build, just enter the directory and run:

```bash
make config [ARCH=<target-arch>] [PREFIX=<prefix>] [SHRINK=<shrinklevel>]
```

`ARCH` is the name of an architecture for which bootlin provides a
toolchain. For example, to compile a 32-bit ARM executable, you'd set
`ARCH` to `armv7-eabihf`, as can be seen from the linked page. This is
totally unrelated to the target triplet appended before cross-tools
inside the toolchain. The downloaded archive is the stable version using
`musl` as the C library. If not specified, the toolchain for
`armv7-eabihf` will be downloaded.

`PREFIX` is the installation prefix of the tool, that will be passed to
configuration script (i.e. `./configure --prefix="..."`). The default is
`/system/opt/openssh`.

`SHRINK` defines a _shrink level_, which determines if the build system
will try to make a smaller build. Currently, the following levels are
defined:
* `SHRINK_LEVEL_NONE`: create a regular build, without any attempt to
  make it smaller;
* `SHRINK_LEVEL_BUILD`: make the build smaller by applying only
  techniques available at build time, which have no negative impact on
  runtime performance but may reduce functionality. For example,
  non-essential features may be left out from `openssl` and `openssh`;
* `SHRINK_LEVEL_RUNTIME`: make an even smaller build (it includes
  `SHRINK_LEVEL_BUILD`) by applying techniques that may have a negative
  runtime impact. At the moment, this compresses all executables with
  `upx`, which can reduce the disk size of files up to 70%, but each
  time the programs are run they must decompress themselves, which means
  longer startup times.

This generates a hidden configuration file `.config`, which records the
selected architecture, prefix path as well as the chosen versions of all
packages that are going to be built. This file allows for reproducible
builds so that the same packages are used over and over even if there
are upstream updates.

To actually run the build, just type `make`. `config` must always be
used on its own, so don't do `make config all`.

### Version selection

Makefiles come with default versions for packages and the toolchain,
which have been tested to compile.  In order to avoid frequent updates
to track upstream releases, the build system can query online sources
for the latest upstream versions and use those, rather than the
defaults, at configuration time.

For each of the packages:

* `zlib`
* `openssh`
* `openssl`
* `__toolchain__` (this is not a package name, it's used as a placeholder to refer
  to the toolchain)

one can set the variable `xxx/VERSION` (where `xxx` is one of the items above) in the
following ways:

* keep it undefined: the default version for the package will be used;
* define it to an empty string: requests the latest upstream version to be used;
* define it to a non-empty string: override the default and use this version.

For the expected common case of using the latest versions of _all_ components,
the special variable `__all__/VERSION` shall be defined to `latest`. This
triggers the makefiles to just grab all the latest and greatest versions.

Examples:

```bash
# Override zlib version, but use the defaults for the rest
make config zlib/VERSION=1.2.3
make

# Override the toolchain version, use the defaults for all packages
make config __toolchain__/VERSION=2022.05-1
make

# Use the latest toolchain and openssh
make config __toolchain__/VERSION= openssh/VERSION=
make

# Use the latest versions for packages and the toolchain
make config __all__/VERSION=latest
make
```

## Features

* Builds for different architectures can coexists side by side. A
  configuration file selects the current architecture.
* Online queries for the latest versions.
* If a package version is changed in the configuration file, that
  package, along all of its dependants, are rebuilt automatically.

## Limitations

* The makefiles have no support for patching packages. The assumption
  is that downloaded packages will compile as-is. If you explicitly
  modify a file inside a package build folder and run `make` again, it
  won't rebuild the package because it uses a separate dependency file
  to track that the build has already been done.
* OpenSSL is currently built without assembly optimizations.
* If the prefix is changed inside the configuration file, the whole
  build must be cleaned and re-run manually, as the makefiles won't pick
  this up.

## Requirements

On the host, you'll need:

* GNU coreutils
* GNU tar
* GNU sed
* GNU make
* GNU awk
* GNU autotools (for autoreconf)
* curl
* unzip
* Whatever shell is used for `/bin/sh`, it must support the `pipefail`
  option. Otherwise, see [troubleshooting](#troubleshooting) for a
  workaround.

## Make targets

* `all`: the default, downloads the toolchain, the packages sources,
builds them and prepares a tarball with the static sshd binaries;
* `nuke`: deletes everything, including the configuration file;
* `clean-all`: like `nuke`, but preserves the configuration file;
* `clean-build`: like `clean-all`, but also preserves downloaded sources
  and the toolchain;
* `clean-config`: only deletes build artifacts for the current
  architecture;
* `clean-arch`: only deletes build artifacts and downloads for the
  current architecture.

## Directory structure

    .
    ├── dl                          # All downloads go here
    │   ├── $arch                   # Divided by architecture
    │   │   └── __toolchain__       # Since toolchains are prebuilt
    │   │       └── $version         
    │   └── noarch                  # But sources are common
    │       └── $package             
    │           └── $version        # And we can store multiple versions
    ├── output                      # All build artifacts go here
    │   └── $arch                   # Divided by architecture
    │       ├── bin                 # Binary tarballs go here
    │       │   └── config          # Along with the config that was used for the build
    │       ├── build_dir           # Build directories for unpacked sources
    │       │   ├── $package
    │       │   │   └── $version
    │       │   └── __toolchain__
    │       │       └── $version
    │       ├── staging_dir         # Staging area for installed stuff
    │       │   └── $prefix
    │       └── state_dir           # State files for dependency tracking
    │           ├── __toolchain__
    │           │   └── $version
    │           └── $package
    │               └── $version
    └── package
        ├── openssh
        ├── openssl
        └── zlib

## Examples

```bash
# Default armv7 build
make config
make -j$(nproc)

# Use a different path and architecture
make ARCH=x86-64 PREFIX=/usr/local
make -j$(nproc)
```

## Install under Android

If you need to install sshd on Android, the defaults should be good
enough as the armv7 build will also work on (most) 64 bit devices. To install
it, follow these instructions (with appropriate modifications required by
your device, if any):

* remount the system partition read-write;
* cd to `/`, then extract the tarball with the binaries. This will
  install stuff under `/system/opt/openssh`;
* create a basic `/etc/passwd` file to make `sshd` happy when it looks
  for user homes and shells. Note that, for simplicity, we'll use
    `/system/opt/openssh/etc` as the root user's home:

  ```bash
  echo 'root:x:0:0:root:/system/opt/openssh/etc:/system/bin/sh' >> /etc/passwd
  ```
* generate new host keys for your device and copy them under
  `/system/opt/openssh/etc`;
* finally, upload your public keys to
  `/system/opt/openssh/etc/.ssh/authorized_keys`;
* remount the system partition read-only;
* enjoy!

## Prebuilt binaries

<a name=verify></a>

The latest weekly build from the latest package versions and toolchain
is available as binary packages. Click on the link at the top of the
page or go to the releases pane.

Currently, we build for x86-64, ARMv7 and AArch64. ARM versions are available in
an "Android" variant which simply uses a different installation prefix, to place
stuff under `/system`.

For each deliverable `X`, there is also a `X.sha256.asc` file that you can
download to verify the integrity and authenticity of the release. It contains
the ASCII-armored GPG signature of the SHA256 digest of the file. To check that
your release is fine, grab both files, place them side by side and then run:

```sh
# Grab my public key
gpg --keyserver keys.openpgp.org --recv-keys 40C859330FFDD306ABFD00DF6AEF14B2ECEFA1C8

# Verify the checksum file and then the release
gpg --verify X.sha256.asc
sha256sum -c X.sha256.asc
```

If everything is fine, the output will look like this:

```
gpg: key 6AEF14B2ECEFA1C8: public key "binary-manu (Release signing) <binary-manu.hbtjr@slmail.me>" imported
gpg: Total number processed: 1
gpg:               imported: 1

gpg: Signature made Sun May 24 16:12:57 2026 CEST
gpg:                using RSA key 40C859330FFDD306ABFD00DF6AEF14B2ECEFA1C8
gpg: Good signature from "binary-manu (Release signing) <binary-manu.hbtjr@slmail.me>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 40C8 5933 0FFD D306 ABFD  00DF 6AEF 14B2 ECEF A1C8

X: OK
sha256sum: WARNING: 17 lines are improperly formatted
```

The `gpg` warning can be suppressed by signing my key with one of yours
to make it trusted, but otherwise does not affect the verification.
Warnings from `sha256sum` are harmless: it complains about the signature
lines not being valid digest lines. The important part is that you see
`X: OK` (or whatever the file is named) in the output.

If either the signature or digest verification fail, _do not use_ the
release. It may be a build failure on my part, corruption on your disk,
or maybe some bad people are messing with the repositoryi trying to make
you run malware.

[original-script]: https://gist.github.com/fumiyas/b4aaee83e113e061d1ee8ab95b35608b
[bootlin-toolchains]: https://toolchains.bootlin.com/

## Troubleshooting

<a name=troubleshooting></a>

* __My `/bin/sh` does not support pipefail and I cannot build__

  This may happen, for example, inside containers using trimmed-down
  shells as `/bin/sh`. You can force `make` to use another shell by
  calling it as follows: `make SHELL=/path/to/my/shell`. The chosen
  shell must support POSIX scripting syntax as well as `pipefail`. A
  common option is `bash`.

  Alternatively, to avoid passing `SHELL` to all invocations, set the
  following environment variable:

  ```sh
  export MAKEFLAGS=SHELL=/path/to/my/shell
  ```

<!-- vi: set et sw=2 sts=-1 ts=2 smartindent fo=tcroqna tw=72 : -->
