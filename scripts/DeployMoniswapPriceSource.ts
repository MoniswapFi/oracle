import { network } from "hardhat";
import output from "./output/Oracle.json";
import constants from "./constants/sources.json";
import { deploy, getContractAt } from "./utils/helpers";
import { MoniswapVolatilePriceSource, Oracle } from "../artifacts/types";
import { writeFile, readFile } from "fs/promises";
import { join } from "path";

interface OracleOutput {
  Sources: string[];
  Oracle: string;
}

async function main() {
  const chainId = network.config.chainId as number;
  const deployed = output[chainId as unknown as keyof typeof output];
  const sources = constants[chainId as unknown as keyof typeof output];
  const Sources = deployed.Sources as string[];

  const moniswapPriceSource = await deploy<MoniswapVolatilePriceSource>(
    "MoniswapVolatilePriceSource",
    undefined,
    sources.moniswap.factory,
    sources.moniswap.usdt,
    sources.moniswap.usdc,
    sources.moniswap.dai,
    sources.moniswap.weth
  );
  const mps = await moniswapPriceSource.getAddress();
  Sources.push(mps);

  const oracle = await getContractAt<Oracle>("Oracle", deployed.Oracle);
  await oracle.setPriceSources(Sources);

  const outputDirectory = "scripts/output";
  const outputFile = join(process.cwd(), outputDirectory, "Oracle.json");

  const out: OracleOutput = {
    ...deployed,
    Sources
  };

  try {
    const buf = await readFile(outputFile);
    const contents = JSON.parse(buf.toString());
    await writeFile(outputFile, JSON.stringify({ ...contents, [chainId as any]: out }, null, 2));
  } catch (err) {
    console.error(`Error writing output file: ${err}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
