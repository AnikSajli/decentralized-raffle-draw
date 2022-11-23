const { network, getNamedAccounts } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe ("Raffle unit tests", async function(){
        let raffle, vrfCoordinatorV2Mock

        beforeEach(async function(){
            const { deployer } = await getNamedAccounts();
        })
    })