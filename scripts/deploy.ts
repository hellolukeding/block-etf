import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();

    const counter = await viem.deployContract("Counter");

    console.log("Counter deployed to:", counter.address);

    // Test the contract
    console.log("Initial value:", await counter.read.x());

    await counter.write.inc();
    console.log("After increment:", await counter.read.x());

    await counter.write.incBy([5n]);
    console.log("After incrementing by 5:", await counter.read.x());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
