# Youcognito Ghosts (YGHOST): 1 of 1,000 on-chain pixel ghosts on Base

**Status: NOT DEPLOYED.** Package for Bankr's CREATE2 deployer on Base mainnet.

- `bankr/`: creation bytecode, standard-json input (recompiles byte-identical with solc v0.8.24+commit.e11b9ed9), ABI, artifact, arg-encoding scripts.
- `constructor-args.hex` is intentionally absent: the owner and royalty receiver will be a Safe multisig whose address is pending. Generate with `bankr/encode-args-safe.sh <SAFE>`.
- `contract/`: Foundry sources and tests (`forge test`; fork test: `FORK_URL=https://mainnet.base.org forge test`). OpenZeppelin v5.1.0 sources are embedded in `bankr/input.json`.
- Starts paused. Owner reserve of 10 (`ownerMint(to, traits)`, works while paused) incl. #1, then `unpause()`. Public `mint` is one per wallet; IDs ≤ 100 free (gas only); after that an owner-set YOUCOG price goes straight from the minter to the faucet. The contract holds no funds and has no withdraw or upgrade path.
- Art: 32x32 SVG rendered fully on-chain from 38 cosmetics (hat 9, shades 7, sheet 6, aura 5, trail 5, prop 6). `previewSvg(traits)` renders any outfit.

Sample renders: `sample-ghost1.png`, `sample-ghost-full.png`.
