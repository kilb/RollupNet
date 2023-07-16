# ccross

## deploy

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
npx hardhat deploy-zksync --script deploy/deploy-zksync-token.ts

# L1 Manager
npx hardhat run --network Goerli deploy/deploy-manager.ts

# L2 Channel
CONTRACT=ARBChannel npx hardhat run --network Arbitrum deploy/deploy-channel.ts
CONTRACT=OPChannel npx hardhat run --network Optimism deploy/deploy-channel.ts
CONTRACT=PolyChannel npx hardhat run --network zkEVM deploy/deploy-channel.ts
CONTRACT=ScrollChannel npx hardhat run --network Scroll deploy/deploy-channel.ts
CONTRACT=MetisChannel npx hardhat run --network Metis deploy/deploy-channel.ts
npx hardhat deploy-zksync --script deploy/deploy-zksync.ts
```

## Test Contracts

TestToken: 0x88a5035499978534d0aD672CE717d2009f9B4E66

TestToken-zksync: 0x627dD03F977Df2eA5B60bA49210D9de45D351f49

L1 Manager: 0x7F4f165EE1aAe7de36724244238471C13f1B9141

OP Channel 10:  0xBaB906E8B0A77411348FacAD2AdCD589c8Fb370F

ARB Channel 42161: 0xBaB906E8B0A77411348FacAD2AdCD589c8Fb370F

Poly 1101: 0xBaB906E8B0A77411348FacAD2AdCD589c8Fb370F

Scroll 534352: 0xBaB906E8B0A77411348FacAD2AdCD589c8Fb370F

Metis 1088: 0xBaB906E8B0A77411348FacAD2AdCD589c8Fb370F

ZKSync 324: 0x09cCd00a8b2C5B02B931B6099eaA5cA42FE5B62D