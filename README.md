# Time Lock Wallet

Installation:

```shell
npm install
```

Compile:
```shell
npx hardhat compile
```

Deploy:

Set environment variables:
Compile:
```shell
export DEPLOYER_PRIVATE_KEY=... (without 0x)
export INFURA_KEY=... (to deploy to kovan)
```

Run deployment on hardhat:
```shell
npx hardhat deploy --network hardhat
```

Run deployment on kovan:
```shell
npx hardhat deploy --network kovan
```

