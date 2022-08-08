import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SimpleBankMapping", function() {

    //Deploy with funds
    async function deploySimpleBankMappingFixture() {
        const ONE_GWEI = 1_000_000_000;
    
        const lockedAmount = ONE_GWEI;
    
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
    
        const SimpleBankMapping = await ethers.getContractFactory("SimpleBankMapping");
        const simpleBankMapping = await SimpleBankMapping.deploy({ value: lockedAmount });

        return { simpleBankMapping, lockedAmount, owner, otherAccount };
    }

    //Deploy without funds
    async function deploySimpleBankMappingNoFundsFixture() {
        const [owner, otherAccount] = await ethers.getSigners();
    
        const SimpleBankMapping = await ethers.getContractFactory("SimpleBankMapping");
        const simpleBankMapping = await SimpleBankMapping.deploy({ value: 0 });

        return { simpleBankMapping, owner, otherAccount };
    }

    describe("Deployment", function () {

        it("Should set the owner", async function () {
            const { simpleBankMapping, owner } = await loadFixture(deploySimpleBankMappingFixture);
            expect(await simpleBankMapping.owner()).to.equal(owner.address);
        });

    });

    describe("modifiers", function(){
        it("isEnrolled(), should revert when the user is not enrolled", async function () {
            const {simpleBankMapping, otherAccount} = await loadFixture(deploySimpleBankMappingFixture);
            
            await expect(simpleBankMapping.connect(otherAccount).withdraw(1000000000)).to.be.revertedWith(
                "Account is not registered"
            );
    
        });

        it("validAmount(), should revert when the amount is < 0", async function () {
            const {simpleBankMapping, owner} = await loadFixture(deploySimpleBankMappingFixture);
            
            await expect(simpleBankMapping.connect(owner).withdraw(0)).to.be.revertedWith(
                "Amount is not valid"
            );
    
        });
    });

    describe("getBalance()", function() {
        it("Should return balance of owner", async function(){
            const {simpleBankMapping, lockedAmount} = await loadFixture(deploySimpleBankMappingFixture);
            const response = await simpleBankMapping.getBalance();
            expect(response).to.equal(lockedAmount);
        });
    });

    describe("enroll()", function() {
        describe("Events", function() {
            it("Should emit an event on new user enrolled", async function () {
                const {simpleBankMapping, otherAccount} = await loadFixture(deploySimpleBankMappingFixture);

                await expect(simpleBankMapping.connect(otherAccount).enroll())
                    .to.emit(simpleBankMapping, "LogEnrolled")
                    .withArgs(otherAccount.address);
            });
        });

        it("Should revert with user allready enrolled", async function () {
            const {simpleBankMapping, owner} = await loadFixture(deploySimpleBankMappingFixture);

            await expect(simpleBankMapping.connect(owner).enroll()).to.be.revertedWith(
                "User already enrolled"
            );
        });
    });

    describe("withdraw()", function() {
        
        describe("Events", function () {
            it("Should emit an event on withdrawal", async function () {
              const { simpleBankMapping, owner } = await loadFixture(deploySimpleBankMappingFixture);
      
              await expect(simpleBankMapping.connect(owner).withdraw(1_000))
                .to.emit(simpleBankMapping, "LogWithdrawal")
                .withArgs(owner.address, 1_000, 999999000);
            });
        });

        it("Should not revert", async function () {
            const {simpleBankMapping, owner} = await loadFixture(deploySimpleBankMappingFixture);
            
            await expect(simpleBankMapping.connect(owner).withdraw(1_000)).to.not.be.reverted;
        });

        describe("Transfers", function () {
            it("Should withdraw the funds to the given address", async function () {
              const { simpleBankMapping, owner } = await loadFixture(
                deploySimpleBankMappingFixture
              );
      
              //espero que la cuenta del owner cambie en 1000 WEI
              await expect(simpleBankMapping.withdraw(1_000)).to.changeEtherBalances(
                [owner],
                [1_000]
              );
            });
          });

    });

    describe("withdrawAll()", function() {

        describe("Events", function () {
            it("Should emit an event on withdrawal", async function () {
              const { simpleBankMapping, owner } = await loadFixture(deploySimpleBankMappingFixture);
      
              await expect(simpleBankMapping.connect(owner).withdrawAll())
                .to.emit(simpleBankMapping, "LogWithdrawal")
                .withArgs(owner.address, 1_000_000_000, 0);
            });
        });

        it("Should revert with insuficient funds", async function () {
            const { simpleBankMapping, owner } = await loadFixture(deploySimpleBankMappingNoFundsFixture);
            await expect(simpleBankMapping.connect(owner).withdrawAll()).to.be.revertedWith(
                "Insuficient funds"
            );
        });

        describe("Transfers", function() {
            it("Should withdraw all funds to the owner", async function (){
                const { simpleBankMapping, owner, lockedAmount } = await loadFixture(
                    deploySimpleBankMappingFixture
                );
        
                //espero que la cuenta del owner cambie en lockedAmount WEI
                await expect(simpleBankMapping.connect(owner).withdrawAll()).to.changeEtherBalances(
                    [owner],
                    [lockedAmount]
                );
            });
        });
    });

    describe("deposit()", function (){
        
        describe("Events", function () {
            it("Should emit an event on deposit made", async function () {
                const { simpleBankMapping, owner, otherAccount, lockedAmount } = await loadFixture(deploySimpleBankMappingFixture);
        
                //Registro otra cuenta
                const connectedSimpleBankContract = simpleBankMapping.connect(otherAccount);
                connectedSimpleBankContract.enroll();

                //Me conecto como owner
                await expect(simpleBankMapping.connect(owner).deposit(otherAccount.address, lockedAmount))
                    .to.emit(simpleBankMapping, "LogDepositMade")
                    .withArgs(otherAccount.address, lockedAmount);
            });
        });

        describe("Transfers", function() {
            it("Should transfer all funds from owner to otherAcount", async function (){
                const { simpleBankMapping, owner, otherAccount, lockedAmount } = await loadFixture(
                    deploySimpleBankMappingFixture
                );
                //Registro otra cuenta
                const connectedSimpleBankContract = simpleBankMapping.connect(otherAccount);
                connectedSimpleBankContract.enroll();
        
                //espero que la cuenta del owner cambie en lockedAmount WEI y se lo transfiera a la otherAccount
                //TODO: balance de owner no cambió ? 
                await expect(simpleBankMapping.connect(owner).deposit(otherAccount.address, lockedAmount)).to.changeEtherBalances(
                    [otherAccount, owner],
                    [lockedAmount, 0]
                );
            });
        });

    });



});