#!/bin/sh
set -eu

template="srcpkgs/aria2/template"
update="srcpkgs/aria2/update"

[ -s "$template" ] || {
    echo "Missing package template: $template" >&2
    exit 1
}
[ -s "$update" ] || {
    echo "Missing update file: $update" >&2
    exit 1
}

grep -Eq '^pkgname=aria2$' "$template"
grep -Eq '^version=[0-9]+\.[0-9]+\.[0-9]+$' "$template"
grep -Eq '^revision=[0-9]+$' "$template"
grep -Fq 'build_style=gnu-configure' "$template"
grep -Fq '--with-openssl' "$template"
grep -Fq '--with-libexpat' "$template"
grep -Fq '--without-gnutls' "$template"
grep -Fq '--enable-libaria2' "$template"
grep -Fq 'archs="x86_64-musl"' "$template"
grep -Fq 'lib32disabled=yes' "$template"
grep -Fq 'CFLAGS+=" -march=skylake -mtune=skylake"' "$template"
grep -Fq 'CXXFLAGS+=" -march=skylake -mtune=skylake"' "$template"
grep -Fq 'c-ares-devel expat-devel gmp-devel openssl-devel sqlite-devel' "$template"
grep -Fq 'zlib-devel' "$template"
grep -Fq 'libaria2_package()' "$template"
grep -Fq 'libaria2-devel_package()' "$template"
grep -Fq 'releases/download/release-' "$template"

if grep -Eq 'march=native|mtune=native|x86_64-glibc|x86_64$' "$template"; then
    echo "The package must remain Skylake-specific and x86_64-musl-only." >&2
    exit 1
fi

checksum="$(sed -n 's/^checksum=//p' "$template")"
[ "${#checksum}" -eq 64 ] || {
    echo "Expected a 64-character source SHA-256 checksum." >&2
    exit 1
}
case "$checksum" in
    *[!0-9a-f]*|'')
        echo "Source checksum must be lowercase hexadecimal." >&2
        exit 1
        ;;
esac

grep -Fq 'pkgname="release"' "$update"

echo "aria2 x86_64-musl / Skylake template checks passed"
