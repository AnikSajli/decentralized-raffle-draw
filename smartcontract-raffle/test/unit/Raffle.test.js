const { assert, expect } = require("chai");
const { network, getNamedAccounts, deployments, ethers } = require("hardhat");
const { developmentChains, networkConfig } = require("../../helper-hardhat-config");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe ("Raffle unit tests", async function(){
        let raffle, raffleContract, vrfCoordinatorV2Mock, raffleEntranceFee, interval, participant
        const chainId = network.config.chainId;

        beforeEach(async () => {
            accounts = await ethers.getSigners();
            participant = accounts[1];
            await deployments.fixture(["mocks", "raffle"]);
            vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
            raffleContract = await ethers.getContract("Raffle");
            raffle = raffleContract.connect(participant);
            raffleEntranceFee = await raffle.getEntranceFee();
            interval = await raffle.getInterval();
        });

        describe("Constructor", async function() {
            it("Initializes the raffle contract", async function() {
                const raffleState = (await raffle.getRaffleState()).toString();
                assert.equal(raffleState, "0");
                assert.equal(
                    interval.toString(),
                    networkConfig[network.config.chainId]["keepersUpdateInterval"]
                )
            })
        });

        describe("enterRaffle", function () {
              it("reverts when you don't pay enough", async () => {
                  await expect(raffle.enterRaffle()).to.be.revertedWith(
                      "Raffle_NotEnoughBalance"
                  )
              })
              it("records player when they enter", async () => {
                  await raffle.enterRaffle({ value: raffleEntranceFee })
                  const contractParticipant = await raffle.getParticipant(0);
                  assert.equal(participant.address, contractParticipant);
              })
              it("emits event on enter", async () => {
                  await expect(raffle.enterRaffle({ value: raffleEntranceFee })).to.emit( 
                      raffle,
                      "RaffleEnter"
                  )
              })
              it("doesn't allow entrance when raffle is calculating", async () => {
                  await raffle.enterRaffle({ value: raffleEntranceFee });
                  await network.provider.send("evm_increaseTime", [interval.toNumber() + 1]);
                  await network.provider.request({ method: "evm_mine", params: [] });
                  await raffle.performUpkeep([]);
                  await expect(raffle.enterRaffle({ value: raffleEntranceFee })).to.be.revertedWith( 
                      "Raffle_NotOpen"
                  )
              })
          });

    })