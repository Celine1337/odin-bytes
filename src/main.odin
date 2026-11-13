// odin-bytes - parse and format byte sizes. Pure Odin, no dependencies.
//
// Two complementary operations on human byte sizes:
//
//   parse   "1.5GiB"        -> 1610612736      (size  -> integer bytes)
//   format  1610612736      -> "1.50 GiB"      (bytes -> human, binary/IEC)
//   format  1500 --si       -> "1.50 KB"       (bytes -> human, decimal/SI)
//
// Units understood by `parse` (case-insensitive, optional space before the
// unit, a bare number means bytes):
//   decimal / SI : B, KB, MB, GB, TB, PB   (powers of 1000)
//   binary / IEC : B, KiB, MiB, GiB, TiB, PiB (powers of 1024)
// Fractional amounts such as "1.5GiB" or "0.5MB" are accepted and rounded to
// the nearest whole byte.
//
// `format` picks the largest unit whose value is at least 1 and prints two
// decimals, except for plain bytes which print as an integer ("N B"). By
// default it uses binary (IEC) units; pass --si for decimal (SI) units.
//
// Exit codes:
//   0  success
//   1  invalid input (bad number, unknown unit, negative size, ...)
//   2  bad usage / missing arguments
package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

usage :: proc() {
	fmt.eprintln("usage:")
	fmt.eprintln("  odin-bytes parse <size>           e.g. \"1.5GiB\" -> bytes")
	fmt.eprintln("  odin-bytes format <bytes> [--si]  e.g. 1610612736 -> \"1.50 GiB\"")
	os.exit(2)
}

invalid :: proc(msg: string) {
	fmt.eprintf("odin-bytes: %s\n", msg)
	os.exit(1)
}

// Multiplier for a unit suffix, case-insensitive. An empty unit means bytes.
// Decimal units are powers of 1000; binary units are powers of 1024.
unit_multiplier :: proc(unit: string) -> (f64, bool) {
	u, _ := strings.to_upper(unit)
	switch u {
	case "", "B":
		return 1, true
	case "KB":
		return 1e3, true
	case "MB":
		return 1e6, true
	case "GB":
		return 1e9, true
	case "TB":
		return 1e12, true
	case "PB":
		return 1e15, true
	case "KIB":
		return 1024, true
	case "MIB":
		return 1048576, true
	case "GIB":
		return 1073741824, true
	case "TIB":
		return 1099511627776, true
	case "PIB":
		return 1125899906842624, true
	}
	return 0, false
}

// Parse a size string into a whole number of bytes.
do_parse :: proc(input: string) {
	s := strings.trim_space(input)
	if len(s) == 0 {
		invalid("empty size")
	}
	// Scan the numeric prefix: optional sign, digits, at most one '.'.
	i := 0
	if s[0] == '+' || s[0] == '-' {
		i = 1
	}
	seen_digit := false
	seen_dot := false
	for i < len(s) {
		c := s[i]
		if c >= '0' && c <= '9' {
			seen_digit = true
			i += 1
		} else if c == '.' && !seen_dot {
			seen_dot = true
			i += 1
		} else {
			break
		}
	}
	if !seen_digit {
		invalid(fmt.tprintf("no number in %q", input))
	}
	numstr := s[:i]
	unit := strings.trim_space(s[i:])
	value, ok := strconv.parse_f64(numstr)
	if !ok {
		invalid(fmt.tprintf("bad number %q", numstr))
	}
	if value < 0 {
		invalid("negative size")
	}
	mult, known := unit_multiplier(unit)
	if !known {
		invalid(fmt.tprintf("unknown unit %q", unit))
	}
	// Round to the nearest whole byte and guard against u64 overflow.
	bytes_f := math.floor(value*mult + 0.5)
	if bytes_f >= 18446744073709551616.0 {
		invalid("size out of range")
	}
	fmt.printf("%d\n", u64(bytes_f))
}

// Format a whole number of bytes into a human-readable string.
do_format :: proc(input: string, si: bool) {
	bytes, ok := strconv.parse_u64(input, 10)
	if !ok {
		invalid(fmt.tprintf("bad byte count %q", input))
	}
	base: f64
	if si {
		base = 1000
	} else {
		base = 1024
	}
	si_names := [?]string{"B", "KB", "MB", "GB", "TB", "PB"}
	iec_names := [?]string{"B", "KiB", "MiB", "GiB", "TiB", "PiB"}
	names := iec_names
	if si {
		names = si_names
	}
	// Pick the largest unit whose factor still fits (value >= 1 of that unit).
	k := 0
	factor: f64 = 1
	f: f64 = 1
	for j := 1; j < len(names); j += 1 {
		f *= base
		if f64(bytes) >= f {
			k = j
			factor = f
		}
	}
	if k == 0 {
		fmt.printf("%d B\n", bytes)
	} else {
		fmt.printf("%.2f %s\n", f64(bytes)/factor, names[k])
	}
}

main :: proc() {
	args := os.args
	if len(args) < 2 {
		usage()
	}
	switch args[1] {
	case "parse":
		if len(args) != 3 {
			usage()
		}
		do_parse(args[2])
	case "format":
		if len(args) < 3 || len(args) > 4 {
			usage()
		}
		si := false
		if len(args) == 4 {
			if args[3] != "--si" {
				usage()
			}
			si = true
		}
		do_format(args[2], si)
	case:
		usage()
	}
}