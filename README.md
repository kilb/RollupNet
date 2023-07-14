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

L1 Manager: 0xEe74e477204A9Cf28bfd235a46A07fba1434D2F4

OP Channel 10:  0xcAB07BDA4BB67f03236C99768bC67ad4cBaA7a89

ARB Channel 42161: 0xcAB07BDA4BB67f03236C99768bC67ad4cBaA7a89

Poly 1101: 0xcAB07BDA4BB67f03236C99768bC67ad4cBaA7a89

Scroll 534352: 0xcAB07BDA4BB67f03236C99768bC67ad4cBaA7a89

Metis 1088: 0xcAB07BDA4BB67f03236C99768bC67ad4cBaA7a89

ZKSync 324: 0xac3089F99dfb8D3B520Bb52F5674Dc28d0928ae1