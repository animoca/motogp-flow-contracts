import { expect } from "@jest/globals";
import path from "path";
import { emulator, init, deployContractByName, getAccountAddress, sendTransaction, executeScript, getFlowBalance } from "flow-js-testing";
import { TX_SUCCESS_STATUS } from "./constants";
import _ from "lodash";
import { SHA3 } from 'sha3';
import { ec as EC } from "elliptic";

jest.setTimeout(10000000);

describe("SalesContract tests.\n\n\tRunning tests:...", () => {

    let addressMap = {};
    const serviceAddress = "0xf8d6e0586b0a20c7" //values from emulator
    addressMap["FungibleToken"] = "0xee82856bf20e2aa6";
    addressMap["FlowToken"] = "0x0ae53cb6e3f42a79";
    addressMap["FlowStorageFees"] = serviceAddress;

    beforeAll(async () => {
        const basePath = path.resolve(__dirname, "../cadence");
        const port = 8080;
        init(basePath, port);
        await emulator.start(port);    
    });

    afterAll(async () => {
        await emulator.stop();
    });

    async function deployContract({ contractName, accountName}) {
        const address = await getAccountAddress(accountName);
        addressMap[contractName] = address;
        let tx = await deployContractByName({ name: contractName, to: address, addressMap });
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    };

    test("Mint some more FLOW tokens for the MotoGP account to avoid storage-over-capacity errors", async () => {
        const recipient = await getAccountAddress("MotoGP");
        const amount = '1000.00';
        const tx = await sendTransaction("mint-flow",[serviceAddress],[recipient, amount]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Mint some more FLOW tokens for the Bob account so he can buy some packs", async () => {
        const recipient = await getAccountAddress("Bob");
        const amount = '300.00';
        const tx = await sendTransaction("mint-flow",[serviceAddress],[recipient, amount]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Deploy NonFungibleToken", async () => await deployContract({ contractName: "NonFungibleToken", accountName: "MotoGP"}));
    test("Deploy ContractVersion", async () => await deployContract({ contractName: "ContractVersion", accountName: "MotoGP"}));
    test("Deploy MotoGPPack", async () => await deployContract({ contractName: "MotoGPPack", accountName: "MotoGP"}));
    test("Deploy MotoGPAdmin", async () => await deployContract({ contractName: "MotoGPAdmin", accountName: "MotoGP"}));
    test("Deploy MotoGPCounter", async () => await deployContract({ contractName: "MotoGPCounter", accountName: "MotoGP"}));
    test("Deploy MotoGPCardMetadata", async () => await deployContract({ contractName: "MotoGPCardMetadata", accountName: "MotoGP"}));
    test("Deploy MotoGPCard", async () => await deployContract({ contractName: "MotoGPCard", accountName: "MotoGP"}));
    test("Deploy PackOpener", async () => await deployContract({ contractName: "PackOpener", accountName: "MotoGP"}));
    test("Deploy Debug", async () => await deployContract({ contractName: "Debug", accountName: "MotoGP"}));
    test("Deploy MotoGPTransfer", async () => await deployContract({ contractName: "MotoGPTransfer", accountName: "MotoGP"}));
    test("Deploy SalesContract", async () => await deployContract({ contractName: "SalesContract", accountName: "MotoGP" }));

    test("Provision pack collection for MotoGP", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        const tx = await sendTransaction("provision-pack-collection", [MotoGP]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Provision pack collection for Bob", async () => {
        const Bob = await getAccountAddress("Bob");
        const tx = await sendTransaction("provision-pack-collection", [Bob]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Adds pack types 1 to 7", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        async function addSinglePackType(packType, numCards) {
            const tx = await sendTransaction("add-pack-type", [MotoGP], [packType, numCards]);
            expect(tx.status).toBe(TX_SUCCESS_STATUS);
        }
        async function addAllPackTypes() {
            const numberOfCards = 3;
            for (let i = 1; i <= 7; i++) {
                await addSinglePackType(i, numberOfCards);
            }
        }
        await addAllPackTypes();
    });

    // Throw-away key pair only used for this test (created with "flow keys generate")
    const PRIVATE_KEY = "2c4970e6cb10f2954c077bf5dd66dc419a5e6e42aa2e1651d1ba947187c985c2";
    const PUBLIC_KEY = "31ebdd6c0b8280b9593c616335598437a09424a2b663ed742db499d179c9b170ef4aa83efc3ea0acc2fc9bae8a1a43070e90e7fe12db3b62f3a2b01a02f6c0ae";

    const rightPaddedHexBuffer = (value, pad) => Buffer.from(value.padEnd(pad * 2, 0), "hex");
    const USER_DOMAIN_TAG_HEX = rightPaddedHexBuffer(Buffer.from("FLOW-V0.0-user").toString("hex"), 32).toString("hex");
 
    const MESSAGE = "FOO";
    const MESSAGE_HEX = Buffer.from(MESSAGE).toString("hex");

    function MockServer() {
        async function signMessage(msg) {
            const ec = new EC("p256");
            const key = ec.keyFromPrivate(Buffer.from(PRIVATE_KEY), "hex");
            const sha = new SHA3(256);
            sha.update(Buffer.from(msg, "hex"));
            const digest = sha.digest();
            const sig = key.sign(digest);
            const n = 32;
            const r = sig.r.toArrayLike(Buffer, "be", n);
            const s = sig.s.toArrayLike(Buffer, "be", n);
            return Buffer.concat([r, s]).toString("hex");
        }
        return { signMessage };
    }

    test("sign offchain with private key and verify on chain with public key in script", async () => {
        const signature = await MockServer().signMessage(USER_DOMAIN_TAG_HEX + MESSAGE_HEX);
        let verificationResult = await executeScript("verify-signature-text", [MESSAGE_HEX, signature]);
        expect(verificationResult).toBe(true);
    });

    test("set public key on sales contract", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        const tx = await sendTransaction("set-public-key-in-sales-contract", [MotoGP],[PUBLIC_KEY]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("sign offchain, verify onchain in script, with numeric input", async () => {
        const MESSAGE_INT_ARRAY = [255]; // this should be the random number
        const MESSAGE_HEX_FROM_INT_ARRAY = Buffer.from(MESSAGE_INT_ARRAY).toString("hex");
        const signature = await MockServer().signMessage(USER_DOMAIN_TAG_HEX + MESSAGE_HEX_FROM_INT_ARRAY);
        let verificationResult = await executeScript("verify-signature-numeric", [MESSAGE_HEX_FROM_INT_ARRAY, signature]);
        expect(verificationResult).toBe(true);
    });

    const SKU_NAME = "sku-1";

    test("Add SKU to SalesContract, and Read SKU data from SalesContract", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        const payoutAddress = MotoGP;
        let startTime = Math.floor(Date.now() / 1000 - 86400);
        let packType = 3;
        let endTime = Math.floor((Date.now() / 1000) + 86400);
        let tx = await sendTransaction("add-sku-to-sales-contract", [MotoGP], [startTime, endTime, SKU_NAME, payoutAddress, packType]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
        let sku = await executeScript("get-sku-from-sales-contract", [SKU_NAME] );
        expect(sku.startTime).toBe(startTime);
        expect(sku.endTime).toBe(endTime);
    });

    test("Get active SKU", async () => {
        let currentSkuNames = await executeScript("get-active-skus-in-sales-contract");
        expect(currentSkuNames.length).toBe(1);
        expect(currentSkuNames[0]).toBe(SKU_NAME);
    });

    async function addSupplyList(supplyList, skuName){
        const MotoGP = await getAccountAddress("MotoGP");
        let tx = await sendTransaction("add-supply-list-to-sales-contract", [MotoGP], [skuName, supplyList]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    }

    test("Add supply to SKU", async () => {
        let start = 1;
        let step = 60;
        for (let i = 0; i < 100; i++){
            let list = [];
            for (let j = start; j < start + step; j++){
                list.push(j);
            }
            start += step;
            await addSupplyList(list, SKU_NAME);
        }

        let sku = await executeScript("get-sku-from-sales-contract", [SKU_NAME] );
        expect(sku.totalSupply).toBe(6000);
        expect(sku.serialList.length).toBe(6000);
        expect(sku.serialList[5999]).toBe(6000);

        let totalSupply = await executeScript("get-total-supply-for-sku-in-sales-contract", [SKU_NAME]);
        expect(totalSupply).toBe(6000);
    });

    test("Try to add an already added serial for a packtype", async () => {
        try {
            await addSupplyList([1], SKU_NAME);
            throw "Can add already-added serial to packtype!"
        } catch (e) {
            
        }
    });

    const SKU_NAME_2 = "sku-2";
    let startTimeSku2;
    let endTimeSku2;

    test("Add SKU to SalesContract", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        const payoutAddress = MotoGP;
        startTimeSku2 = Math.floor(Date.now() / 1000);
        endTimeSku2 = Math.floor((Date.now() + 86400) / 1000);
        const packType = 3;
        let tx = await sendTransaction("add-sku-to-sales-contract", [MotoGP], [startTimeSku2, endTimeSku2, SKU_NAME_2, payoutAddress, packType]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    const SKU_PRICE = '2.55';

    test("Set SKU price", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        let tx = await sendTransaction("set-price-of-sku-in-sales-contract", [MotoGP], [SKU_NAME, SKU_PRICE]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Set max packs per buyer", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        const maxPacks = 10;
        let tx = await sendTransaction("set-max-per-buyer-per-sku-in-sales-contract", [MotoGP], [SKU_NAME, maxPacks]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
        let buyCount = await executeScript("get-max-per-buyer-for-sku-in-sales-contract", [SKU_NAME]);
        expect(buyCount).toBe(10);
    })

    test("Get start and end time via time helper methods on contract", async () => {
        let startTime = await executeScript("get-starttime-for-sku-in-sales-contract", [SKU_NAME_2] );
        expect(startTime).toBe(startTimeSku2); 
        let endTime = await executeScript("get-endtime-for-sku-in-sales-contract", [SKU_NAME_2]);
        expect(endTime).toBe(endTimeSku2);
        try {
            let startTime = await executeScript("get-starttime-for-sku-in-sales-contract", ["wrong name"] );
            throw "Doesn't panic on wrong name: " + startTime
        } catch (e) {
            
        }
        try {
            let endTime = await executeScript("get-endtime-for-sku-in-sales-contract", ["wrong name"] );
            throw "Doesn't panic on wrong name: " + endTime
        } catch (e) {
            
        }
    });

    test("verify by building original message and nonce, skuName and address as separate arguments", async () => {
        let nonce = 160000001;
        let recipientAddress = (await getAccountAddress("Bob")).toString();
        let originalMessage = SKU_NAME_2 + recipientAddress + nonce.toString();
        const messageHex = Buffer.from(originalMessage).toString("hex");
        const combinedHex = USER_DOMAIN_TAG_HEX + messageHex;
        const signature = await MockServer().signMessage(combinedHex); 
        let [ isValid, builtMessage ] = await executeScript("verify-with-nonce-address-and-skuname", [signature, nonce, SKU_NAME_2, recipientAddress]);
        expect(isValid).toBe(true);
        expect(builtMessage).toBe(originalMessage);
    });

    test("get remaining supply before sale", async () => {
        let remainingSupply = await executeScript("get-remaining-supply-for-sku-in-sales-contract", [SKU_NAME]);
        expect(remainingSupply).toBe(6000);
    });

    async function getBuyCount(skuName, recipient) {
        let buyCount = await executeScript("get-buy-count-for-address-in-sales-contract", [skuName, recipient]);
        return buyCount;
    }

    async function buyFromContract(recipientName, nonce, packType){

        let recipientAddress = (await getAccountAddress(recipientName)).toString();

        let nonceFromContractBefore = await executeScript("get-nonce-from-sales-contract", [recipientAddress]);

        let sku = await executeScript("get-sku-from-sales-contract", [SKU_NAME] );
        let supply = sku.serialList.length;
        
        let originalMessage = SKU_NAME + recipientAddress + nonce.toString() + packType.toString();
        const messageHex = Buffer.from(originalMessage).toString("hex");
        const combinedHex = USER_DOMAIN_TAG_HEX + messageHex;
        const signature = await MockServer().signMessage(combinedHex);
        const tx = await sendTransaction("buy-pack-from-sales-contract", [recipientAddress], [signature, nonce, packType, SKU_NAME, recipientAddress]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
        
        sku = await executeScript("get-sku-from-sales-contract", [SKU_NAME] );
        expect(sku.serialList.length).toBe(supply - 1);

        let nonceFromContractAfter = await executeScript("get-nonce-from-sales-contract", [recipientAddress]);
        expect(nonceFromContractAfter - nonceFromContractBefore).toBe(1);
    }

    test("get buy count for address from sales contract", async () => {
        const Bob = await getAccountAddress("Bob");
        const buyCount = await getBuyCount(SKU_NAME, Bob);
        expect(buyCount).toBe(0);
    });

    test("Buy from sales contract", async () => {
        const price = await executeScript("get-price-for-sku-in-sales-contract", [SKU_NAME]);
        const MotoGP = await getAccountAddress("MotoGP");
        const Bob = await getAccountAddress("Bob");
        let bobBalanceBefore = await getFlowBalance(Bob);
        let payoutBalanceBefore = await getFlowBalance(MotoGP);

        let bobsPackCount = await executeScript("get-owned-packs", [Bob]);
        expect(bobsPackCount.length).toBe(0);
        const packType = 3;
        await buyFromContract("Bob", 1, packType);

        bobsPackCount = await executeScript("get-owned-packs", [Bob]);
        expect(bobsPackCount.length).toBe(1);
       
        let payoutBalanceAfter = await getFlowBalance(MotoGP);
       
        let bobBalanceAfter = await getFlowBalance(Bob);
        let diffPayoutVault = parseFloat(payoutBalanceAfter).toFixed(2) - parseFloat(payoutBalanceBefore).toFixed(2);
        expect(parseFloat(diffPayoutVault).toFixed(2)).toBe(parseFloat(price).toFixed(2));
        let diffBobVault = parseFloat(bobBalanceBefore).toFixed(2) - parseFloat(bobBalanceAfter).toFixed(2);
        expect(parseFloat(diffBobVault).toFixed(2)).toBe(parseFloat(price).toFixed(2));
        let packTypeInfo = await executeScript("get-pack-type-info", [packType]);
        
        let assignedPackNumbers = packTypeInfo.assignedPackNumbers;
        
        let serials = Object.keys(assignedPackNumbers)
      
        let isMinted = await executeScript("is-serial-minted-for-pack-type", [packType, parseInt(serials[0])]);
        expect(isMinted).toBe(true);
    });

    test("get buy count for address from sales contract", async () => {
        const Bob = await getAccountAddress("Bob");
        const buyCount = await getBuyCount(SKU_NAME, Bob);
        expect(buyCount).toBe(1);
    });

    test("Get remaining supply after sale", async () => {
        let remainingSupply = await executeScript("get-remaining-supply-for-sku-in-sales-contract", [SKU_NAME]);
        expect(remainingSupply).toBe(5999);
    });

    test("Get currently active SKU from sales contract", async () => {
        let activeSkuNames = await executeScript("get-active-skus-in-sales-contract");
        expect(activeSkuNames.length).toBe(2);
        expect(activeSkuNames[0]).toBe(SKU_NAME);
    });

    test("Buy with same nonce for same user and fail", async () => {
        const sameNonce = 1;
        try {
            await buyFromContract("Bob", sameNonce, 3);
            throw "Can use same nonce twice!"
        } catch (e) {
            const Bob = await getAccountAddress("Bob")
            expect(e).toContain("error: panic: Nonce " + sameNonce + " for " + Bob + " already used\n");
        }
    });

    test("Buy with a higher nonce for same user", async () => {
        await buyFromContract("Bob", 2, 3);
    });

    test("Get remaining supply after sale", async () => {
        let remainingSupply = await executeScript("get-remaining-supply-for-sku-in-sales-contract", [SKU_NAME]);
        expect(remainingSupply).toBe(5998);
    });

    test("Buy with a too high nonce for same user", async () => {
        const tooHighNonce = 4;
        try {
            await buyFromContract("Bob",tooHighNonce, 3);
            throw "Can not skip a nonce!"
        } catch (e) {
            const Bob = await getAccountAddress("Bob")
            expect(e).toContain("error: panic: Nonce " + tooHighNonce + " for " + Bob + " is not next nonce\n");
        }
    });

    test("get buy count for address from sales contract", async () => {
        const Bob = await getAccountAddress("Bob");
        const buyCount = await getBuyCount(SKU_NAME, Bob);
        expect(buyCount).toBe(2);
    });

    test("remove a sku", async () => {
        let allSkuNamesBefore  = await executeScript("get-all-sku-names-in-sales-contract");
        const MotoGP = await getAccountAddress("MotoGP");
        let tx = await sendTransaction("remove-sku-from-sales-contract", [MotoGP], [SKU_NAME]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
        let allSkuNamesAfter  = await executeScript("get-all-sku-names-in-sales-contract");
        expect(allSkuNamesBefore.length - allSkuNamesAfter.length).toBe(1)
    });

    test("test padding logic", async () => {
        let ADDRESS_0 = "0x252c7419f2282991";
        let padded0 = await executeScript("test-address-padding",[ADDRESS_0]);
        expect(padded0).toBe(ADDRESS_0);

        let ADDRESS_1 = "0x052c7419f2282991";
        let padded1 = await executeScript("test-address-padding",[ADDRESS_1]);
        expect(padded1).toBe(ADDRESS_1);

        let ADDRESS_2 = "0x002c7419f2282991";
        let padded2 = await executeScript("test-address-padding",[ADDRESS_2]);
        expect(padded2).toBe(ADDRESS_2);

        let ADDRESS_3 = "0x000c7419f2282991";
        let padded3 = await executeScript("test-address-padding",[ADDRESS_3]);
        expect(padded3).toBe(ADDRESS_3);

        let ADDRESS_4 = "0x00007419f2282991";
        let padded4 = await executeScript("test-address-padding",[ADDRESS_4]);
        expect(padded4).toBe(ADDRESS_4);

        let ADDRESS_5 = "0x00000419f2282991"
        let padded5 = await executeScript("test-address-padding",[ADDRESS_5]);
        expect(padded5).toBe(ADDRESS_5);
    });

    test("can change starttime timestamp on sku", async () => {

        const SKU_NAME_5 = "sku-5";
        const MotoGP = await getAccountAddress("MotoGP");

        // add new sku
        const payoutAddress = MotoGP;
        let startTime = Math.floor(Date.now() / 1000);
        let packType = 3;
        let endTime = Math.floor((Date.now() / 1000) + 86400);
        let tx = await sendTransaction("add-sku-to-sales-contract", [MotoGP], [startTime, endTime, SKU_NAME_5, payoutAddress, packType]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);

        let tsBefore = await executeScript("get-starttime-for-sku-in-sales-contract", [SKU_NAME_5]);
        const newStartTime = tsBefore + 100;

        const txChangeTs = await sendTransaction("set-starttime-on-sku-in-salescontract", [MotoGP], [SKU_NAME_5, newStartTime]);
        expect(txChangeTs.status).toBe(TX_SUCCESS_STATUS);

        let tsAfter = await executeScript("get-starttime-for-sku-in-sales-contract", [SKU_NAME_5]);
        expect(newStartTime).toBe(tsAfter);
    });

    test("can change endtime timestamp on sku", async () => {

        const SKU_NAME_5 = "sku-6";
        const MotoGP = await getAccountAddress("MotoGP");

        // add new sku
        const payoutAddress = MotoGP;
        let startTime = Math.floor(Date.now() / 1000);
        let packType = 3;
        let endTime = Math.floor((Date.now() / 1000) + 86400);
        let tx = await sendTransaction("add-sku-to-sales-contract", [MotoGP], [startTime, endTime, SKU_NAME_5, payoutAddress, packType]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);

        let tsBefore = await executeScript("get-endtime-for-sku-in-sales-contract", [SKU_NAME_5]);
        const newEndTime = tsBefore + 100;

        const txChangeTs = await sendTransaction("set-endtime-for-sku-in-salescontract", [MotoGP], [SKU_NAME_5, newEndTime]);
        expect(txChangeTs.status).toBe(TX_SUCCESS_STATUS);

        let tsAfter = await executeScript("get-endtime-for-sku-in-sales-contract", [SKU_NAME_5]);
        expect(newEndTime).toBe(tsAfter);
    });

    test("test that remove admin tx works", async () => {
        let MotoGP = await getAccountAddress("MotoGP");
        let tx = await sendTransaction("remove-sales-contract-admin", [MotoGP]); 
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

});