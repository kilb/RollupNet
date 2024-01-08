# RollupNet

Trustless State Channels for Real-time Cross Rollup Contract Execution

## How to deploy

### compile

```
npx hardhat compile
```

### deploy

```bash
# TestToken
CONTRACT=ABCToken npx hardhat run --network Arbitrum deploy/deploy-token.ts
CONTRACT=ABCToken npx hardhat run --network Optimism deploy/deploy-token.ts
CONTRACT=ABCToken npx hardhat run --network zkEVM deploy/deploy-token.ts
CONTRACT=ABCToken npx hardhat run --network Scroll deploy/deploy-token.ts
CONTRACT=ABCToken npx hardhat run --network Metis deploy/deploy-token.ts
CONTRACT=ABCToken npx hardhat run --network Mantle deploy/deploy-token.ts
npx hardhat deploy-zksync --script deploy/deploy-zksync-token.ts

# L1 Manager
npx hardhat run --network Goerli deploy/deploy-manager.ts

# L2 Channel
CONTRACT=ARBChannel npx hardhat run --network Arbitrum deploy/deploy-channel.ts
CONTRACT=OPChannel npx hardhat run --network Optimism deploy/deploy-channel.ts
CONTRACT=PolyChannel npx hardhat run --network zkEVM deploy/deploy-channel.ts
CONTRACT=ScrollChannel npx hardhat run --network Scroll deploy/deploy-channel.ts
CONTRACT=MetisChannel npx hardhat run --network Metis deploy/deploy-channel.ts
CONTRACT=MantleChannel npx hardhat run --network Mantle deploy/deploy-channel.ts
npx hardhat deploy-zksync --script deploy/deploy-zksync.ts
```

## Test Contracts

TestToken: 0x88a5035499978534d0aD672CE717d2009f9B4E66

TestToken-zksync: 0x627dD03F977Df2eA5B60bA49210D9de45D351f49

L1 Manager: 0x88736e6d0Cb9C016A916e0D5827dCBD6BAF1c192

☑ OP Channel 10:  0xc840C4ef73f869F6ddA0b6334AF6AB7F2bF03c11

☑ ARB Channel 42161: 0xc840C4ef73f869F6ddA0b6334AF6AB7F2bF03c11

Poly 1101: 0xc840C4ef73f869F6ddA0b6334AF6AB7F2bF03c11

☑ Scroll 534352: 0xc840C4ef73f869F6ddA0b6334AF6AB7F2bF03c11

Metis 1088: 0xc840C4ef73f869F6ddA0b6334AF6AB7F2bF03c11

Mantle 5000: 0xc840C4ef73f869F6ddA0b6334AF6AB7F2bF03c11

☑ ZKSync 324: 0x4351B047eE64c063baC4351A4ed640433d29568d