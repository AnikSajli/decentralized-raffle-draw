const { network } = require("hardhat")

const BASE_FEE = "250000000000000000" 
const GAS_PRICE_LINK = 1e9

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
 
    if (chainId == 31337) {
        log("Deploying mocks for local network...")
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: [BASE_FEE, GAS_PRICE_LINK],
        })
        log("Mock VRFCoordinatorV2 contract Deployed!")
        log("You need a local network running to interact")
        log("run `yarn hardhat console --network localhost` to interact with the deployed smart contracts!")
    }
}

module.exports.tags = ["all", "mocks"]