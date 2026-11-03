#!/usr/bin/env bash
# Re-encode constructor args with a Safe multisig as owner AND royalty receiver.
# Usage: ./encode-args-safe.sh SAFE_ADDRESS [ROYALTY_RECEIVER]
# Refuses if SAFE_ADDRESS has no code on Base (i.e. is not a deployed Safe).
set -euo pipefail
[ $# -ge 1 ] || { echo "usage: $0 SAFE_ADDRESS [ROYALTY_RECEIVER]" >&2; exit 1; }
export PATH="$HOME/.foundry/bin:$PATH"
CODE=$(cast code "$1" --rpc-url https://mainnet.base.org)
[ "$CODE" != "0x" ] || { echo "no contract code at $1 on Base: not a Safe" >&2; exit 1; }
cd "$(dirname "$0")"
./encode-args.sh "$1" 0x3067ab541253746AB353b842Fdc0970ffBDe13c7 "${2:-$1}"
