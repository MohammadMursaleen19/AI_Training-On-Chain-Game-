const hre = require("hardhat");

async function main() {
  console.log("🚀 Starting deployment of AI-Training On-Chain Game...");
  
  // Get the deployer account
  const [deployer] = await hre.ethers.getSigners();
  
  console.log("📝 Deploying contracts with account:", deployer.address);
  console.log("💰 Account balance:", (await deployer.getBalance()).toString());
  
  // Get the contract factory
  const Project = await hre.ethers.getContractFactory("Project");
  
  console.log("⏳ Deploying Project contract...");
  
  // Deploy the contract
  const project = await Project.deploy();
  
  await project.deployed();
  
  console.log("✅ Project contract deployed!");
  console.log("📍 Contract address:", project.address);
  
  // Display deployment summary
  console.log("\n" + "=".repeat(50));
  console.log("🎮 AI-TRAINING ON-CHAIN GAME DEPLOYMENT SUMMARY");
  console.log("=".repeat(50));
  console.log(`📍 Contract Address: ${project.address}`);
  console.log(`🌐 Network: ${hre.network.name}`);
  console.log(`👤 Deployer: ${deployer.address}`);
  console.log(`💰 Deployer Balance: ${hre.ethers.utils.formatEther(await deployer.getBalance())} ETH`);
  console.log("=".repeat(50));
  
  // Verify contract on Core Testnet 2 (if verification is available)
  if (hre.network.name === "core_testnet2") {
    console.log("\n⏳ Waiting for block confirmations...");
    await project.deployTransaction.wait(6);
    
    try {
      console.log("🔍 Verifying contract on Core Testnet 2...");
      await hre.run("verify:verify", {
        address: project.address,
        constructorArguments: [],
      });
      console.log("✅ Contract verified successfully!");
    } catch (error) {
      console.log("❌ Contract verification failed:", error.message);
    }
  }
  
  // Save deployment info to file
  const fs = require('fs');
  const deploymentInfo = {
    network: hre.network.name,
    contractAddress: project.address,
    deployer: deployer.address,
    blockNumber: project.deployTransaction.blockNumber,
    transactionHash: project.deployTransaction.hash,
    timestamp: new Date().toISOString()
  };
  
  fs.writeFileSync(
    `deployment-${hre.network.name}.json`,
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log(`📄 Deployment info saved to deployment-${hre.network.name}.json`);
  
  // Display next steps
  console.log("\n" + "🎯 NEXT STEPS:");
  console.log("1. Save the contract address for frontend integration");
  console.log("2. Fund the contract if needed for prize pool");
  console.log("3. Test the contract functionality");
  console.log("4. Deploy to mainnet when ready");
  
  return project.address;
}

// Error handling
main()
  .then((address) => {
    console.log(`\n🎉 Deployment completed successfully!`);
    console.log(`Contract address: ${address}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
