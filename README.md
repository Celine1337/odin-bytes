<p align="center">
  <img src="assets/banner.svg" width="830" alt="odin-bytes banner">
</p>
<p align="center">
  <a href="https://github.com/Celine1337/odin-bytes/releases"><img src="assets/nav-releases.svg" alt="Releases"></a>
  <a href="https://en.wikipedia.org/wiki/Binary_prefix"><img src="assets/nav-spec.svg" alt="Binary prefixes"></a>
  <a href="LICENSE"><img src="assets/nav-mit.svg" alt="MIT"></a>
</p>

<img src="assets/section-about.svg" width="830" alt="About">

**odin-bytes** converts between human byte sizes and raw byte counts, in both directions, from the shell. `parse` turns a size like `1.5GiB` into the exact integer `1610612736`; `format` turns a byte count back into a readable string like `1.50 GiB`. It understands both unit families — decimal/SI (`KB`, `MB`, `GB`, …, powers of 1000) and binary/IEC (`KiB`, `MiB`, `GiB`, …, powers of 1024) — case-insensitively, with an optional space between the number and the unit, and fractional amounts like `0.5MB`.

Why Odin? Because it compiles to a small, fast native binary with a clean standard library (`strconv`, `strings`, `fmt`) and no runtime or garbage-collector surprises — a single `main.odin` is a legitimate systems utility. No dependencies, no package manager, one build step.

<img src="assets/section-features.svg" width="830" alt="Features">

- **Two-way conversion** — `parse` (size → bytes) and `format` (bytes → size) cover both directions.
- **Both unit families** — decimal/SI (`B KB MB GB TB PB`, ×1000) and binary/IEC (`B KiB MiB GiB TiB PiB`, ×1024).
- **Forgiving input** — case-insensitive units, optional space (`1.5 GiB`), fractional values (`0.5MB`), and a bare integer means bytes.
- **Sensible formatting** — picks the largest unit whose value is ≥ 1 and prints two decimals; plain bytes print as an integer (`999 B`).
- **`--si` switch** — `format` defaults to binary units; pass `--si` for decimal.
- **Clear failure modes** — invalid input goes to stderr with exit `1`; bad usage exits `2`.
- **Zero dependencies** — one Odin file; builds to a single native binary.
- **Tested** — a self-contained `test.sh` asserts exact outputs and exit codes.

<img src="assets/section-stack.svg" width="830" alt="Tech stack">

<img src="assets/section-install.svg" width="830" alt="Install">

Requires the [Odin](https://odin-lang.org) compiler. Odin links via `clang`; a `clang` that forwards to `gcc` works fine.

```bash
git clone https://github.com/Celine1337/odin-bytes.git
cd odin-bytes
./build.sh          # compiles to bin/odin-bytes
./bin/odin-bytes parse "1.5GiB"
```

Or compile directly:

```bash
odin build src -out:bin/odin-bytes
```

<img src="assets/section-usage.svg" width="830" alt="Usage">

```bash
odin-bytes parse "1.5GiB"        # -> 1610612736
odin-bytes parse "0.5MB"         # -> 500000
odin-bytes format 1610612736     # -> 1.50 GiB  (binary)
odin-bytes format 1500 --si      # -> 1.50 KB   (decimal)
odin-bytes format 999            # -> 999 B
```

```text
$ odin-bytes parse "1.5GiB"
1610612736
$ odin-bytes format 1610612736
1.50 GiB
$ odin-bytes format 1500 --si
1.50 KB
```

Exit codes: `0` success, `1` invalid input, `2` bad usage / missing arguments.

<img src="assets/section-license.svg" width="830" alt="License">

MIT — see [LICENSE](LICENSE).