# YoucogGhosts – Bankr deploy package (Base mainnet). NOT DEPLOYED.
- creation-bytecode.hex – 0x-prefixed creation bytecode (20,704 B initcode; 18,823 B runtime, EIP-170 limit 24,576)
- YoucogGhosts.artifact.json – Foundry artifact; abi.json – ABI only
- input.json – solc standard-json input (all 37 sources incl. OpenZeppelin v5.1.0); recompiles byte-identical
- compiler-version.txt – v0.8.24+commit.e11b9ed9 (optimizer on, 200 runs, evm cancun)
- contract-target.txt – src/YoucogGhosts.sol:YoucogGhosts
- encode-args.sh OWNER FAUCET ROYALTY_RECEIVER [YOUCOG] -> constructor-args.hex (NOT included: owner = Andy's Safe, address pending)

Constructor: (owner, faucet, royaltyReceiver, youcog). Owner is explicit (Bankr CREATE2 proxy is msg.sender).
Starts PAUSED, price 0, freeUntil 100. Flow: owner ownerMint(#1) -> unpause.
Mint paths: mint() public, one per wallet, ids <= freeUntil free, else `price` YOUCOG pulled minter->faucet;
ownerMint() 10 reserve incl. #1. No ETH accepted, no withdraw, no upgrade, renounce disabled, Ownable2Step.
Owner: pause/unpause, setPrice, setFreeUntil, setRoyaltyReceiver (5% fixed), setVoucherSigner (0 = off).
Renderer is an internal library (inlined), so there is one contract and nothing to link.
- encode-args-safe.sh SAFE -> constructor-args.hex with the Safe as owner and royalty receiver (refuses an address with no code)
