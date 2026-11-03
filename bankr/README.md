# YoucogGhosts – Bankr deploy package (Base mainnet). NOT DEPLOYED.
- creation-bytecode.hex – 0x-prefixed creation bytecode (20,704 B initcode; 18,823 B runtime, EIP-170 limit 24,576)
- YoucogGhosts.artifact.json – Foundry artifact; abi.json – ABI only
- input.json – solc standard-json input (all 37 sources incl. OpenZeppelin v5.1.0); recompiles byte-identical
- compiler-version.txt – v0.8.24+commit.e11b9ed9 (optimizer on, 200 runs, evm cancun)
- contract-target.txt – src/YoucogGhosts.sol:YoucogGhosts
- constructor-args.hex: owner = royaltyReceiver = 0xa959d8eeded6fb440ca584d1e87e581168bbf628 (Andy, Farcaster wallet), faucet 0x3067…13c7, YOUCOG 0x92Bf…EbA3. encode-args.sh regenerates it.

Constructor: (owner, faucet, royaltyReceiver, youcog). Owner is explicit (Bankr CREATE2 proxy is msg.sender).
Starts PAUSED, price 0, freeUntil 100. Flow: owner ownerMint(#1) -> unpause.
Mint paths: mint() public, one per wallet, ids <= freeUntil free, else `price` YOUCOG pulled minter->faucet;
ownerMint() 10 reserve incl. #1. No ETH accepted, no withdraw, no upgrade, renounce disabled, Ownable2Step.
Owner: pause/unpause, setPrice, setFreeUntil, setRoyaltyReceiver (5% fixed), setVoucherSigner (0 = off).
Renderer is an internal library (inlined), so there is one contract and nothing to link.
- encode-args-safe.sh SAFE -> constructor-args.hex with the Safe as owner and royalty receiver (refuses an address with no code)
