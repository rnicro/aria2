# aria2 for Void Linux (x86_64-musl / Intel Skylake)

A hardware-specific Void Linux XBPS package for [aria2](https://github.com/aria2/aria2), targeting **x86_64-musl** and Intel Skylake. The reference processor is the Intel Core i3-6100U.

This repository packages upstream aria2; it does not fork or patch the application source. The package recipe follows Void Linux's `srcpkgs/aria2/template`.

## Target and compatibility

- Distribution: Void Linux
- XBPS target: `x86_64-musl` only
- CPU target: Intel Skylake (`-march=skylake -mtune=skylake`)
- Reference CPU: Intel Core i3-6100U (2 cores / 4 threads)
- C library: musl
- Build system: GNU Autotools / `gnu-configure`

This is not a generic x86_64 binary. Skylake compiler flags may emit instructions unsupported by older x86_64 processors. It is not intended for pre-Skylake CPUs, glibc systems, or other architectures.

GitHub Actions builds the package on a hosted runner. The runner is only the build host; XBPS selects the `x86_64-musl` target, and the recipe supplies the Skylake instruction-set tuning. Build parallelism follows the runner, not the laptop's two physical CPU cores.

## Package source and build

The package recipe follows Void Linux's [aria2 template](https://github.com/void-linux/void-packages/tree/master/srcpkgs/aria2).

- Upstream release: **1.37.0**
- Source archive: `https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0.tar.xz`
- SHA-256: `60a420ad7085eb616cb6e2bdf0a7206d68ff3d37fb5a956dc44242eb2f79b66b`
- Build style: GNU configure
- CPU tuning: `-march=skylake -mtune=skylake` for both C and C++
- TLS: OpenSSL; GnuTLS is disabled
- Runtime dependencies: CA certificates
- Build dependencies: c-ares, Expat, GMP, OpenSSL, SQLite, and zlib

The Void dependency set enables aria2's normal HTTP/FTP and BitTorrent/Metalink capabilities, asynchronous DNS, TLS, XML/Metalink parsing, and session database support where detected by the upstream configure checks. The package retains Void's `libaria2` runtime and `libaria2-devel` subpackages.

Void supplies the normal release optimization flags; this repository adds only the Skylake CPU target. It deliberately does not use `-march=native`, because the CI runner is not the target device. LTO and PGO are not enabled by this recipe. No runtime speedup is claimed without benchmarking on the actual i3-6100U.

## Install a release

Successful builds from `main` publish an immutable, versioned GitHub Release. The tag format is `<version>_<revision>` (initially `1.37.0_1`). The release contains these installable packages:

```text
aria2-1.37.0_1.x86_64-musl.xbps
libaria2-1.37.0_1.x86_64-musl.xbps
libaria2-devel-1.37.0_1.x86_64-musl.xbps
```

Download the `aria2` and `libaria2` packages from the same release and install them locally:

```sh
sudo xbps-install ./aria2-1.37.0_1.x86_64-musl.xbps ./libaria2-1.37.0_1.x86_64-musl.xbps
aria2c --version
```

The `libaria2-devel` package is only needed when compiling software against the aria2 library. Download packages from [GitHub Releases](https://github.com/rnicro/aria2/releases).

These are standalone XBPS package files, not a signed, indexed XBPS repository. The package is not intended for older CPUs or glibc systems.

## Build locally

On a Void Linux host, clone both repositories and overlay this package recipe into Void's package tree:

```sh
git clone https://github.com/rnicro/aria2.git
git clone https://github.com/void-linux/void-packages.git

rm -rf void-packages/srcpkgs/aria2
cp -a aria2/srcpkgs/aria2 void-packages/srcpkgs/

cd void-packages
./xbps-src -A x86_64-musl binary-bootstrap
./xbps-src -A x86_64-musl pkg aria2
```

The generated packages are written under `hostdir/binpkgs/`. On a glibc x86_64 build host, keep `-A x86_64-musl` on both commands; do not replace the target flags with `-march=native`.

## Validation and maintenance

Run the repository checks before pushing:

```sh
bash -n srcpkgs/aria2/template
sh -n scripts/publish-release.sh
sh -n scripts/test-template.sh
sh scripts/test-template.sh
```

When updating aria2:

1. Verify the upstream release and source archive SHA-256.
2. Update `version` and `checksum` in `srcpkgs/aria2/template`.
3. Keep revision 1 for the first packaging of a new upstream version; increment it when packaging changes alter the package output.
4. Re-check Void's aria2 template for dependency, configure-option, or musl changes.
5. Run the validation checks and confirm `./xbps-src -A x86_64-musl pkg aria2` succeeds.
6. Benchmark on the reference Skylake CPU before describing a runtime performance improvement.

## References

- [Upstream aria2](https://github.com/aria2/aria2)
- [aria2 releases](https://github.com/aria2/aria2/releases)
- [Void Linux aria2 package](https://github.com/void-linux/void-packages/tree/master/srcpkgs/aria2)
- [Void Linux XBPS source packages](https://github.com/void-linux/void-packages)
- [rnicro/tofi](https://github.com/rnicro/tofi), [rnicro/brightnessctl](https://github.com/rnicro/brightnessctl), and [rnicro/velotype](https://github.com/rnicro/velotype), used as examples for Skylake-specific `x86_64-musl` packaging and release workflows.
