#!/usr/bin/env bash
# Self-contained test suite for odin-bytes. Requires the Odin compiler.
set -uo pipefail
cd "$(dirname "$0")"
export TC="$HOME/.local/toolchains"
export PATH="$TC/odin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
command -v odin >/dev/null 2>&1 || { echo "FAIL: odin not found"; exit 1; }
./build.sh >/dev/null
BIN="./bin/odin-bytes"
pass=0; fail=0
ok(){ pass=$((pass+1)); }
bad(){ fail=$((fail+1)); echo "FAIL: $1"; }
# substring match on output + exit code
check(){ # name expected_exit expected_substring actual_exit actual_out
  local name="$1" want_rc="$2" want="$3" rc="$4" out="$5"
  if [ "$rc" != "$want_rc" ]; then bad "$name (exit $rc, want $want_rc)"; return; fi
  if [ -n "$want" ] && ! printf '%s' "$out" | grep -qF -- "$want"; then
    bad "$name (output missing '$want')"; return
  fi
  ok
}
# exact match on output + exit code
checkeq(){ # name expected_exit expected_exact actual_exit actual_out
  local name="$1" want_rc="$2" want="$3" rc="$4" out="$5"
  if [ "$rc" != "$want_rc" ]; then bad "$name (exit $rc, want $want_rc)"; return; fi
  if [ "$out" != "$want" ]; then bad "$name (output '$out', want '$want')"; return; fi
  ok
}

# --- parse ---
out=$($BIN parse "1.5GiB"); rc=$?
checkeq "parse 1.5GiB" 0 "1610612736" "$rc" "$out"

out=$($BIN parse "1.5 GiB"); rc=$?
checkeq "parse with space" 0 "1610612736" "$rc" "$out"

out=$($BIN parse "100"); rc=$?
checkeq "parse plain integer" 0 "100" "$rc" "$out"

out=$($BIN parse "2kb"); rc=$?
checkeq "parse lowercase decimal" 0 "2000" "$rc" "$out"

out=$($BIN parse "2KIB"); rc=$?
checkeq "parse uppercase binary" 0 "2048" "$rc" "$out"

out=$($BIN parse "0.5MB"); rc=$?
checkeq "parse fractional decimal" 0 "500000" "$rc" "$out"

out=$($BIN parse "1B"); rc=$?
checkeq "parse explicit bytes" 0 "1" "$rc" "$out"

out=$($BIN parse "3PiB"); rc=$?
checkeq "parse pebibytes" 0 "3377699720527872" "$rc" "$out"

out=$($BIN parse "1.5TB"); rc=$?
checkeq "parse terabytes" 0 "1500000000000" "$rc" "$out"

# --- format ---
out=$($BIN format 1610612736); rc=$?
checkeq "format binary GiB" 0 "1.50 GiB" "$rc" "$out"

out=$($BIN format 1500 --si); rc=$?
checkeq "format SI KB" 0 "1.50 KB" "$rc" "$out"

out=$($BIN format 1024); rc=$?
checkeq "format 1 KiB" 0 "1.00 KiB" "$rc" "$out"

out=$($BIN format 999); rc=$?
checkeq "format below unit stays bytes" 0 "999 B" "$rc" "$out"

out=$($BIN format 0); rc=$?
checkeq "format zero" 0 "0 B" "$rc" "$out"

out=$($BIN format 1000 --si); rc=$?
checkeq "format SI 1 KB" 0 "1.00 KB" "$rc" "$out"

out=$($BIN format 1048576); rc=$?
checkeq "format 1 MiB" 0 "1.00 MiB" "$rc" "$out"

out=$($BIN format 1500); rc=$?
checkeq "format binary rounds" 0 "1.46 KiB" "$rc" "$out"

# --- errors ---
out=$($BIN parse "abc" 2>&1); rc=$?
check "parse non-number exits 1" 1 "odin-bytes" "$rc" "$out"

out=$($BIN parse "12XB" 2>&1); rc=$?
check "parse unknown unit exits 1" 1 "unknown unit" "$rc" "$out"

out=$($BIN parse "-5" 2>&1); rc=$?
check "parse negative exits 1" 1 "negative" "$rc" "$out"

out=$($BIN format "xyz" 2>&1); rc=$?
check "format bad count exits 1" 1 "bad byte count" "$rc" "$out"

out=$($BIN 2>&1); rc=$?
check "no args exits 2" 2 "usage" "$rc" "$out"

out=$($BIN parse 2>&1); rc=$?
check "parse missing size exits 2" 2 "usage" "$rc" "$out"

out=$($BIN bogus 2>&1); rc=$?
check "unknown command exits 2" 2 "usage" "$rc" "$out"

echo "----------------------------------------"
echo "odin-bytes: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && echo "ALL CHECKS PASSED" || exit 1