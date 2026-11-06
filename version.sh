#!/usr/bin/env bash
set -exo pipefail

# Accepted release version formats (POSIX extended regexes, unanchored)
# OpenSSH portable: 10.6p2, or 3.8.1p1 from the 2.x/3.x era
OPENSSH_VERSION_RE='[0-9]+\.[0-9]+(\.[0-9]+)?p[0-9]+'
# OpenSSL 3.0 and later: 4.0.3
OPENSSL_VERSION_RE='[0-9]+\.[0-9]+\.[0-9]+'
# zlib: 1.4, 1.3.1 (the four-component development tags are not releases)
ZLIB_VERSION_RE='[0-9]+\.[0-9]+(\.[0-9]+)?'

list_github_tags() {
  git ls-remote --tags --refs "$1" | grep -o 'refs/tags/.*' | cut -d/ -f3-
}

list_bootlin_versions_and_extensions() {
  local arch
  arch="$1"
  curl -sL "https://toolchains.bootlin.com/downloads/releases/toolchains/$arch/tarballs/" |
    sed -En 's/.*href="'"$arch"'--musl--stable-([^"]+)\.tar\.([^"]+)".*/\1 \2/p'
}

list_bootlin_versions() {
  local arch
  arch="$1"
  list_bootlin_versions_and_extensions "$arch" | cut -f 1 -d " "
}

check_bootlin_extension() {
  local arch
  arch="$1"
  local version
  version="$2"
  list_bootlin_versions_and_extensions "$arch" | awk '$1 == "'"$version"'" { print $2; }'
}

# Release versions on the OpenBSD mirror. Keyed on the .asc file, which is
# uploaded last, so a release without its signature yet is never picked.
list_openssh_versions() {
  curl -fsSL --retry 3 https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/ |
    sed -En 's/.*href="openssh-('"$OPENSSH_VERSION_RE"')\.tar\.gz\.asc".*/\1/p'
}

# Release tags only: skips OpenSSL_1_* tags and -alpha/-beta pre-releases
list_openssl_versions() {
  list_github_tags https://github.com/openssl/openssl |
    sed -En 's/^openssl-('"$OPENSSL_VERSION_RE"')$/\1/p'
}

# Release tags only: skips -pre and four-component development tags
list_zlib_versions() {
  list_github_tags https://github.com/madler/zlib |
    sed -En 's/^v('"$ZLIB_VERSION_RE"')$/\1/p'
}

# require_version PACKAGE VERSION REGEX EXAMPLE
# Print VERSION if the whole of it matches REGEX. Otherwise, fail with an error.
require_version() {
  if [ -z "$2" ] || [ "$(printf '%s\n' "$2" | sed -En "/^($3)\$/p")" != "$2" ]; then
    echo "invalid $1 version '$2': expected a release version like $4" >&2
    return 1
  fi
  printf '%s\n' "$2"
}

# Accepts X.YpZ, or a portable git tag (V_X_Y_PZ) that is converted to X.YpZ.
# Only well-formed tags are converted, so an error always shows the input.
normalize_openssh_version() {
  require_version openssh \
    "$(printf '%s\n' "$1" | sed -E '/^V_[0-9]+_[0-9]+(_[0-9]+)?_P[0-9]+$/{s/^V_//; s/_P/p/; y/_/./;}')" \
    "$OPENSSH_VERSION_RE" '10.6p2 (or a portable tag like V_10_6_P2)'
}

# OpenSSL 1.x uses different tag and archive names, which openssl.mk does not
# handle, so it is rejected here instead of failing later with a 404.
normalize_openssl_version() {
  require_version openssl "$1" "$OPENSSL_VERSION_RE" '4.0.3' >/dev/null || return 1
  if [ "${1%%.*}" -lt 3 ]; then
    echo "unsupported openssl version '$1': only 3.0.0 and later are supported" >&2
    return 1
  fi
  printf '%s\n' "$1"
}

normalize_zlib_version() {
  require_version zlib "$1" "$ZLIB_VERSION_RE" '1.4 or 1.3.1'
}
