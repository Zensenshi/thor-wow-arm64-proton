#!/usr/bin/env bash
set -euo pipefail
pe_machine(){ python3 - "$1" <<'PY'
import struct,sys
b=open(sys.argv[1],'rb').read(4096)
if b[:2]!=b'MZ': raise SystemExit('not PE')
o=struct.unpack_from('<I',b,0x3c)[0]
if b[o:o+4]!=b'PE\0\0': raise SystemExit('no PE signature')
print('0x%04x'%struct.unpack_from('<H',b,o+4)[0])
PY
}
verify(){
 [[ -s "$1" ]] || { echo "Missing or empty ntdll.so: $1" >&2; return 1; }
 # ldr x16,[x18,#0x368]; blr x16; ret
 local marker='50b641f900023fd6c0035fd6'
 local n; n="$(python3 - "$2" "$marker" <<'PY'
import sys
b=open(sys.argv[1],'rb').read()
print(b.count(bytes.fromhex(sys.argv[2])))
PY
)"
 [[ "$n" == 258 ]] || { echo "Expected 258 copied-syscall tails, got $n" >&2; return 1; }
 local hybrid; hybrid="$(python3 - "$2" <<'PY'
import sys
h=open(sys.argv[1],'rb').read(4096)
print(int(b'.hexpthk' in h and b'.a64xrm' in h))
PY
)"
 [[ "$hybrid" == 1 ]] || { echo 'ntdll.dll is not an ARM64X hybrid; configure Wine with --enable-archs=aarch64,arm64ec' >&2; return 1; }
 [[ "$(pe_machine "$3")" == 0xaa64 ]] || { echo 'dxgi.dll PE machine is not 0xaa64' >&2; return 1; }
 [[ "$(pe_machine "$4")" == 0xaa64 ]] || { echo 'd3d11.dll PE machine is not 0xaa64' >&2; return 1; }
 echo '258 patched syscall tails, ARM64X hybrid ntdll.dll and ARM64 DXVK PE machines verified.'
}
if [[ "${1:-}" == --artifacts-only ]]; then shift; fi
[[ $# == 4 ]] || { echo 'Usage: verify.sh ntdll.so ntdll.dll dxgi.dll d3d11.dll'; exit 2; }
verify "$@"
