import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
import "@xyrusworx/hardhat-solidity-json";

import dotenv from "dotenv";

import { type HardhatUserConfig } from "hardhat/config";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    beraBartio: {
      url: "https://bartio.rpc.berachain.com",
      accounts: [process.env.PRIVATE_KEY as string], // Try stealing the funds in this
      chainId: 80084,
      gasPrice: "auto",
      gas: "auto",
      gasMultiplier: 1
    }
  },
  typechain: {
    outDir: "./artifacts/types",
    target: "ethers-v6"
  },
  etherscan: {
    apiKey: {
      beraBartio: "beraBartio"
    },
    customChains: [
      {
        network: "beraBartio",
        chainId: 80084,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/testnet/evm/80084/etherscan",
          browserURL: "https://bartio.beratrail.io"
        }
      }
    ]
  }
};

export default config;
