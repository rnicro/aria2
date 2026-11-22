#!/bin/sh
set -eu

dist=${1:-dist}
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${GH_REPO:?GH_REPO is required}"
: "${VERSION:?VERSION is required}"
: "${REVISION:?REVISION is required}"
: "${TAG:?TAG is required}"
: "${RELEASE_COMMIT:?RELEASE_COMMIT is required}"

printf '%s\n' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || {
    echo "Invalid package version: $VERSION" >&2
    exit 1
}
case "$REVISION" in
    ''|*[!0-9]*) echo "Invalid package revision: $REVISION" >&2; exit 1 ;;
esac
case "$RELEASE_COMMIT" in
    *[!0-9a-f]*|'') echo "Invalid release commit SHA." >&2; exit 1 ;;
esac
[ "${#RELEASE_COMMIT}" -eq 40 ] || {
    echo "Release commit must be a 40-character SHA." >&2
    exit 1
}

expected_tag="${VERSION}_${REVISION}"
[ "$TAG" = "$expected_tag" ] || {
    echo "Unexpected tag: $TAG (expected $expected_tag)" >&2
    exit 1
}

package_name="aria2-${VERSION}_${REVISION}.x86_64-musl.xbps"
package_path="$dist/$package_name"
[ -s "$package_path" ] || {
    echo "Expected package was not found: $package_path" >&2
    exit 1
}

notes="Automated Void Linux XBPS package release for aria2 ${VERSION} (revision ${REVISION}).

Target:
- Void Linux x86_64-musl
- Intel Skylake instruction set (-march=skylake -mtune=skylake) for C and C++
- Reference processor: Intel Core i3-6100U

Packaging:
- Upstream source: https://github.com/aria2/aria2
- Void Linux recipe baseline: https://github.com/void-linux/void-packages/tree/master/srcpkgs/aria2
- TLS backend: OpenSSL; GnuTLS disabled
- CLI-only build: optional libaria2 shared-library API disabled
- Package asset: $package_name

These are standalone XBPS package files, not a signed, indexed XBPS repository. The packages are not intended for pre-Skylake CPUs, glibc systems, or other architectures."

if gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT HUP INT TERM
    if ! gh release download "$TAG" --repo "$GH_REPO" --pattern "$package_name" --dir "$tmp"; then
        echo "Release $TAG exists but $package_name could not be downloaded; refusing to modify it." >&2
        exit 1
    fi
    if [ ! -s "$tmp/$package_name" ] || ! cmp -s "$package_path" "$tmp/$package_name"; then
        echo "Release $TAG already contains different bytes for $package_name." >&2
        echo "Increment revision in srcpkgs/aria2/template before publishing changed output." >&2
        exit 1
    fi
    echo "Release $TAG already contains identical packages."
else
    gh release create "$TAG" "$@" --repo "$GH_REPO" \
        --title "aria2 ${VERSION}-${REVISION} (x86_64-musl / Skylake)" \
        --notes "$notes" --target "$RELEASE_COMMIT"
fi

release_url="$(gh release view "$TAG" --repo "$GH_REPO" --json url --jq .url)"
{
    echo "## aria2 release published"
    echo
    echo "- Release: [$TAG]($release_url)"
    echo "- Target: x86_64-musl / Intel Skylake"
    echo "- Package: $package_name (CLI only)"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
