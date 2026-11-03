#!/usr/bin/env bash
# Usage: ./encode-args.sh OWNER FAUCET ROYALTY_RECEIVER [YOUCOG_TOKEN]
# Writes constructor-args.hex next to this script. Constructor:
#   constructor(address owner_, address faucet_, address royaltyReceiver_, address youcog_)
# YOUCOG_TOKEN defaults to the repo's TOKEN (claim-forge-app src/lib/youcog/faucet.server.ts).
# Repo FAUCET_WALLET (src/lib/youcog/holder.server.ts): 0x3067ab541253746AB353b842Fdc0970ffBDe13c7
set -euo pipefail
[ $# -ge 3 ] || { echo "usage: $0 OWNER FAUCET ROYALTY_RECEIVER [YOUCOG_TOKEN]" >&2; exit 1; }
TOKEN="${4:-0x92Bff5D88157114DfC4a0A00F3496AA7e2E7EbA3}"
for a in "$1" "$2" "$3" "$TOKEN"; do
  [[ "$a" =~ ^0x[0-9a-fA-F]{40}$ ]] || { echo "not an address: $a" >&2; exit 1; }
  [ "$a" != "0x0000000000000000000000000000000000000000" ] || { echo "zero address" >&2; exit 1; }
done
export PATH="$HOME/.foundry/bin:$PATH"
for a in "$1" "$2" "$3" "$TOKEN"; do cast to-check-sum-address "$a" >/dev/null; done
OUT="$(cd "$(dirname "$0")" && pwd)/constructor-args.hex"
cast abi-encode "constructor(address,address,address,address)" "$1" "$2" "$3" "$TOKEN" > "$OUT"
echo "wrote $OUT"; cat "$OUT"
echo "Check: owner code (Safe should show bytecode on Base):"; cast code "$1" --rpc-url https://mainnet.base.org | head -c 60; echo
