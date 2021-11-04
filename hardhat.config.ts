import { HardhatUserConfig } from 'hardhat/types';
import 'hardhat-deploy';
import * as dotenv from 'dotenv';

dotenv.config();

const { DEPLOYER_PRIVATE_KEY, INFURA_KEY } = process.env;

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      chainId: 1337
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${INFURA_KEY}`,
      chainId: 42,
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`]
    }
  },
  solidity:  "0.8.4",
  namedAccounts: {
    deployer: 0
  },
};

export default config;
