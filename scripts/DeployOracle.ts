import { network } from "hardhat";
import { deploy } from "./utils/helpers";
import { writeFile, readFile } from "fs/promises";
import { join } from "path";
import { Oracle as OracleContract } from "../artifacts/types";

interface OracleOutput {
  Sources: string[];
  Oracle: string;
}

async function main() {
  const chainId = network.config.chainId as number;
  const Sources: string[] = [];

  const oracle = await deploy<OracleContract>("Oracle", undefined, Sources);
  const Oracle = await oracle.getAddress();

  const outputDirectory = "scripts/output";
  const outputFile = join(process.cwd(), outputDirectory, "Oracle.json");

  const output: OracleOutput = {
    Oracle,
    Sources
  };

  try {
    const buf = await readFile(outputFile);
    const contents = JSON.parse(buf.toString());
    await writeFile(outputFile, JSON.stringify({ ...contents, [chainId as any]: output }, null, 2));
  } catch (err) {
    console.error(`Error writing output file: ${err}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
