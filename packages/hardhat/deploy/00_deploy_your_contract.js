// deploy/00_deploy_your_contract.js

//const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("StreamPool", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: ['0xF2B4E81ba39F5215Db2e05B2F66f482BB8e87FD2', //Host
      '0xaD2F1f7cd663f6a15742675f975CcBD42bb23a88', //CFAv1
      '0xAD1e87F0C74341ecAFc1d27349dD6e650f5bAdD7', //IDAv1
      '0xBF6201a6c48B56d8577eDD079b84716BB4918E8A', //fDAIx
      '0x6fC99F5591b51583ba15A8C2572408257A1D2797', //ETHx
      '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506' //sushiRouter
    ],
    gasLimit: 4000000,
    log: true,
  });

  /*
    // Getting a previously deployed contract
    const YourContract = await ethers.getContract("YourContract", deployer);
    await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */
};
module.exports.tags = ["StreamPool"];
