import { network } from "hardhat";
import output from "./output/Oracle.json";
import constants from "./constants/sources.json";
import { deploy, getContractAt } from "./utils/helpers";
import { KodiakFinanceV2PriceSource, Oracle } from "../artifacts/types";
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

  const kodiakV2PriceSource = await deploy<KodiakFinanceV2PriceSource>(
    "KodiakFinanceV2PriceSource",
    undefined,
    sources.kodiakV2.factory,
    sources.kodiakV2.usdt,
    sources.kodiakV2.usdc,
    sources.kodiakV2.weth
  );
  const mps = await kodiakV2PriceSource.getAddress();
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
