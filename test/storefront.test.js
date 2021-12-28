import { expect } from "@jest/globals";
import path from "path";
import { emulator, init, deployContractByName, getAccountAddress, sendTransaction, executeScript, mintFlow, getFlowBalance } from "flow-js-testing";
import { TX_SUCCESS_STATUS } from "./constants";
import _ from "lodash";

jest.setTimeout(1000000);

describe("Tests for NFTStorefront.\n\n\tRunning tests:...", () => {

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

    async function deployContract({ contractName, accountName}){
        const address = await getAccountAddress(accountName);
        addressMap[contractName] = address;
        let tx = await deployContractByName({ name: contractName, to: address, addressMap });
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    };

    test("Mint some more FLOW tokens for the MotoGP account to avoid storage-over-capacity errors", async () => {
        async function mintFlow(amount, name){
            const recipientAddress = await getAccountAddress(name);
            const tx = await sendTransaction("mint-flow",[serviceAddress],[recipientAddress, amount]);
            expect(tx.status).toBe(TX_SUCCESS_STATUS);
        }
        await mintFlow('999.9',"MotoGP");
        await mintFlow('100.0', "Bob");
        await mintFlow('100.0', 'Alice');
        await mintFlow('100.0', 'Roger');
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
    test("Deploy REVV", async () => await deployContract({ contractName: "REVV", accountName: "MotoGP"}));
    test("Deploy NFTStorefront", async () => await deployContract({ contractName: "NFTStorefront", accountName: "MotoGP"}));

    test("Set revv commission receiver on Storefront contract", async () => {

        let isSet = await executeScript("is-revv-commission-receiver-set-on-nft-storefront");
        expect(isSet).toBe(false);

        const MotoGP = await getAccountAddress("MotoGP");
        const tx = await sendTransaction("set-commission-vault-revv-on-nft-storefront", [MotoGP]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);

        isSet = await executeScript("is-revv-commission-receiver-set-on-nft-storefront");
        expect(isSet).toBe(true);
    });

    test("Add pack types to Pack contract", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        async function addSinglePackType({ packType, numCards }) {
            const tx = await sendTransaction("add-pack-type", [MotoGP], [packType, numCards]);
            expect(tx.status).toBe(TX_SUCCESS_STATUS);
        }
       
        for (const packType of _.range(1,8)) {
            await addSinglePackType({ packType, numCards: 3 })
        }
    });

    test("Provision MotoGP account with a pack collection and card collection", async () => {
        async function provisionWithPackAndCardCollections(name){
            const signer = await getAccountAddress(name);
            let tx = await sendTransaction("provision-pack-collection", [signer]);
            expect(tx.status).toBe(TX_SUCCESS_STATUS);
            tx = await sendTransaction("provision-card-collection", [signer]);
            expect(tx.status).toBe(TX_SUCCESS_STATUS);
        }
        await provisionWithPackAndCardCollections("MotoGP");
        await provisionWithPackAndCardCollections("Bob");
        await provisionWithPackAndCardCollections("Alice");
        await provisionWithPackAndCardCollections("Roger");
    });

    test("Provision PackOpener for Bob", async () => {
        const MotoGP = await getAccountAddress("Bob");
        const tx = await sendTransaction("provision-pack-opener", [MotoGP]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Mint packs for BoB", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        const Bob = await getAccountAddress("Bob");
        const packType = 7;
        async function mintAndTransfer(start, end) {
            const serials = _.range(start,end);
            const tx = await sendTransaction("mint-and-transfer-packs",[MotoGP],[Bob, packType, serials]);
            expect(tx.status).toBe(TX_SUCCESS_STATUS);
        }
        await mintAndTransfer(1, 10);
    });

    test("deposit Bob's pack into the PackOpener collection", async () => {
        const Bob = await getAccountAddress("Bob");
        const tx = await sendTransaction("pack-opener-deposit-with-topup",[Bob],[2, Bob]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("opens bob's pack using an Admin reference", async () => {
        const Bob = await getAccountAddress("Bob");
        const MotoGP = await getAccountAddress("MotoGP");
        let packId = 2;//nftId
        let cardIds = [5,6,7];//types
        let serials = [1,2,3];//print numbers
        const tx = await sendTransaction("pack-opener-open-pack",[MotoGP],[Bob, packId, cardIds, serials]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
        const ids = await executeScript("get-cards-in-collection",[Bob]);
        expect(ids.sort()).toEqual([1,2,3]);
    });

    test("Provisions Alice and Bob with a REVV vault.", async () => {
        const provisionRevvVault = async signer => {
            const tx = await sendTransaction("provision-revv-vault", [signer]);
            expect(tx.status).toBe(TX_SUCCESS_STATUS);
            const revvBalance = await executeScript("get-revv-balance",[signer]);
            expect(revvBalance).toBe('0.00000000');
        }
        const Alice = await getAccountAddress("Alice");
        const Bob = await getAccountAddress("Bob");
        await provisionRevvVault(Alice);
        await provisionRevvVault(Bob);
    });

    test("Provisions NFTStorefront for Bob", async () => {
        const Bob = await getAccountAddress("Bob");
        const tx = await sendTransaction("provision-nftstorefront", [Bob]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    let revvPackSaleOfferResourceID;

    let listedPackId;

    test("Bob lists a pack for sale for REVV on storefront", async () => {
        const Bob = await getAccountAddress("Bob");
        // get Bob's pack ids
        let bobsPacks = await executeScript("get-owned-packs", [Bob]);
        let packId = bobsPacks[0];
        listedPackId = packId;
        let price = 10.5;

        // list for sale
        const tx = await sendTransaction("list-pack-for-sale-for-revv-on-nftstorefront", [Bob], [packId, price]);
        let data = tx.events[0].data;
        revvPackSaleOfferResourceID = data.saleOfferResourceID;
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("test that the is-listed script for packs work as expected", async () => {
        const Bob = await getAccountAddress("Bob");
        const result1 = await executeScript("is-pack-listed-on-storefront", [Bob, listedPackId ]);
        expect(result1).toBe(true);

        const unusedId = 500;
        const result2 = await executeScript("is-pack-listed-on-storefront", [Bob, unusedId]);
        expect(result2).toBe(false);
    });

    test("Transfers REVV from Service to Alice.", async () => {
        const recipient = await getAccountAddress("Alice");
        const signer = await getAccountAddress("MotoGP");
        const amount = '100.0';
        const tx = await sendTransaction("transfer-revv", [signer], [recipient,amount]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
        const revvBalance = await executeScript("get-revv-balance",[recipient]);
        expect(parseFloat(revvBalance)).toBe(parseFloat(amount));
    });

    test("Alice buys pack from storefront", async () => {
        const buyer = await getAccountAddress("Alice");
        const seller = await getAccountAddress("Bob");
        const MotoGP = await getAccountAddress("MotoGP");
    
        let adminRevvBalanceBefore = parseFloat((await executeScript("get-revv-balance", [MotoGP])));
    
        let salePrice = parseFloat((await executeScript("get-saleoffer-price-from-storefront",[seller, revvPackSaleOfferResourceID])));
        expect(salePrice).toBe(10.5);

        let commissionRate = parseFloat((await executeScript("get-commission-rate-from-storefront-contract")));
        expect(commissionRate).toBe(0.05);
      
        const tx = await sendTransaction("buy-pack-from-nftstorefront-with-revv", [buyer], [revvPackSaleOfferResourceID, seller]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);

        let adminRevvBalanceAfter = parseFloat((await executeScript("get-revv-balance", [MotoGP])));

        expect((adminRevvBalanceAfter - adminRevvBalanceBefore).toFixed(2)).toBe((salePrice * commissionRate).toFixed(2))
    });

    test("Remove saleOffer after purchase", async () => {
        const Bob = await getAccountAddress("Bob");
        const tx = await sendTransaction("clean-up-saleoffer-from-nftstorefront", [Bob], [Bob, revvPackSaleOfferResourceID]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Change commissionRate", async () => {
        const MotoGP = await getAccountAddress("MotoGP");
        let commissionRate = parseFloat((await executeScript("get-commission-rate-from-storefront-contract")));
        expect(commissionRate).toBe(0.05);
        const newCommissionRate = 0.125
        const tx = await sendTransaction("set-commission-rate-on-nftstorefront", [MotoGP], [newCommissionRate])
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
        commissionRate = parseFloat((await executeScript("get-commission-rate-from-storefront-contract")));
        expect(commissionRate).toBe(newCommissionRate);
    });

    let revvCardSaleOfferResourceID;

    test("Bob lists card for sale for REVV on storefront", async () => {
        const Bob = await getAccountAddress("Bob");
        // get Bob's pack ids
        let bobsCards = await executeScript("get-owned-cards", [Bob]);
        let cardId = bobsCards[0];
        let price = 20.7;

        // list for sale
        const tx = await sendTransaction("list-card-for-sale-for-revv-on-nftstorefront", [Bob], [cardId, price]);     
        let data = tx.events[0].data;
        revvCardSaleOfferResourceID = data.saleOfferResourceID;
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Alice buys a card from storefront", async () => {
        const buyer = await getAccountAddress("Alice");
        const seller = await getAccountAddress("Bob");
        const MotoGP = await getAccountAddress("MotoGP");

        let buyerRevvBalanceBefore = parseFloat((await executeScript("get-revv-balance", [buyer])));
        let adminRevvBalanceBefore = parseFloat((await executeScript("get-revv-balance", [MotoGP])));
        let sellerRevvBalanceBefore = parseFloat((await executeScript("get-revv-balance", [seller])));

        let commissionRate = parseFloat((await executeScript("get-commission-rate-from-storefront-contract")));
        expect(commissionRate).toBe(0.125);

        let salePrice = parseFloat((await executeScript("get-saleoffer-price-from-storefront",[seller, revvCardSaleOfferResourceID])));
        expect(salePrice).toBe(20.7);
        
        const tx = await sendTransaction("buy-card-from-nftstorefront-with-revv", [buyer], [revvCardSaleOfferResourceID, seller]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);

        let adminRevvBalanceAfter = parseFloat((await executeScript("get-revv-balance", [MotoGP])));

        let buyerRevvBalanceAfter = parseFloat((await executeScript("get-revv-balance", [buyer])));

        let sellerRevvBalanceAfter = parseFloat((await executeScript("get-revv-balance", [seller])));

        let adminDiff = (adminRevvBalanceAfter - adminRevvBalanceBefore).toFixed(2);
        let sellerDiff = (sellerRevvBalanceAfter - sellerRevvBalanceBefore).toFixed(2);
        let buyerDiff = (buyerRevvBalanceBefore - buyerRevvBalanceAfter).toFixed(2);

        expect(buyerDiff).toBe((salePrice).toFixed(2));
        expect(parseFloat(adminDiff) + parseFloat(sellerDiff)).toBe(parseFloat(buyerDiff));
    });

    test("Provisions NFTStorefront for Alice", async () => {
        const Alice = await getAccountAddress("Alice");
        const tx = await sendTransaction("provision-nftstorefront", [Alice]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    let flowTokenPackSaleOfferResourceID;

    test("Alice lists a pack for sale for FLOW on storefront", async () => {
        const Alice = await getAccountAddress("Alice")
        // get Bob's pack ids
        let alicesPacks = await executeScript("get-owned-packs", [Alice]);
        let packId = alicesPacks[0];
        let price = 30.5;

        // list for sale
        const tx = await sendTransaction("list-pack-for-sale-for-flow-on-nftstorefront", [Alice], [packId, price]);
        let data = tx.events[0].data;
        flowTokenPackSaleOfferResourceID = data.saleOfferResourceID;
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    let flowTokenCardSaleOfferResourceID;

    let listedCardId;

    test("Alice lists a card for sale for FLOW on storefront", async () => {
        const Alice = await getAccountAddress("Alice");
        // get Alice's pack ids
        let alicesCards = await executeScript("get-owned-cards", [Alice]);
        let cardId = alicesCards[0];
        listedCardId = cardId;
        let price = 12.7;

        // list for sale
        const tx = await sendTransaction("list-card-for-sale-for-flow-on-nftstorefront", [Alice], [cardId, price]);     
        let data = tx.events[0].data;
        flowTokenCardSaleOfferResourceID = data.saleOfferResourceID;
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("test that the is-listed script for cards work as expected", async () => {
        const Alice = await getAccountAddress("Alice");
        const result1 = await executeScript("is-card-listed-on-storefront", [Alice, listedCardId ]);
        expect(result1).toBe(true);

        const unusedId = 1000;
        const result2 = await executeScript("is-card-listed-on-storefront", [Alice, unusedId ]);
        expect(result2).toBe(false);
    });

    test("get all card ids from storefront", async () => {
        const Alice = await getAccountAddress("Alice");
        let allCardIds = await executeScript("get-card-ids-from-nftstorefront", [Alice]);
        expect(allCardIds.length).toBe(1);
    });

    test("get all pack ids from storefront", async () => {
        const Alice = await getAccountAddress("Alice");
        let allPackIds = await executeScript("get-pack-ids-from-nftstorefront", [Alice]);
        expect(allPackIds.length).toBe(1);
    })

    test("Bob buys a card for FLOW", async () => {
        const buyer = await getAccountAddress("Bob");
        const seller = await getAccountAddress("Alice");
        const tx = await sendTransaction("buy-card-from-nftstorefront-with-flow", [buyer], [flowTokenCardSaleOfferResourceID, seller]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Bob buys a pack for FLOW", async () => {
        const buyer = await getAccountAddress("Bob");
        const seller = await getAccountAddress("Alice");
        const tx = await sendTransaction("buy-pack-from-nftstorefront-with-flow", [buyer], [flowTokenPackSaleOfferResourceID, seller]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Bob lists and delists a pack", async () => {
        const Bob = await getAccountAddress("Bob");
        // get Alice's pack ids
        let bobsCards = await executeScript("get-owned-cards", [Bob]);
        let cardId = bobsCards[0];
        let price = 8.5;

        // list for sale
        const listTx = await sendTransaction("list-card-for-sale-for-flow-on-nftstorefront", [Bob], [cardId, price]);     
        let data = listTx.events[0].data;
        const saleOfferResourceID = data.saleOfferResourceID;
        expect(listTx.status).toBe(TX_SUCCESS_STATUS);

        // delist
        const delistTx = await sendTransaction("delist-from-nftstorefront", [Bob], [saleOfferResourceID]);
        expect(delistTx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Roger tries to buy item that Alice has already purchased", async () => {
        const Bob = await getAccountAddress("Bob");
        let bobsCards = await executeScript("get-owned-cards", [Bob]);
        let cardId = bobsCards[0];
        let price = 8.5;

        // list for sale
        let tx = await sendTransaction("list-card-for-sale-for-flow-on-nftstorefront", [Bob], [cardId, price]);     
        let data = tx.events[0].data;
        const saleOfferResourceID = data.saleOfferResourceID;
        expect(tx.status).toBe(TX_SUCCESS_STATUS);

        // alice buys it
        const buyer = await getAccountAddress("Alice");
        const seller = await getAccountAddress("Bob");
        tx = await sendTransaction("buy-card-from-nftstorefront-with-flow", [buyer], [saleOfferResourceID, seller]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);

        //roger tries to buy it and fails
        const newBuyer = await getAccountAddress("Roger");
        try {
            await sendTransaction("buy-card-from-nftstorefront-with-flow", [newBuyer], [saleOfferResourceID, seller]);
            throw "Buyer could buy already-sold item!"
        } catch (e) {
            expect(e).toContain("offer has already been accepted");
        }
    });

    // bob transfers pack to alice
    test("Bob transfers a pack to Alice", async () => {
        const Bob = await getAccountAddress("Bob");
        let bobsPacks = await executeScript("get-owned-packs", [Bob]);
        let packId = bobsPacks[0];
        const Alice = await getAccountAddress("Alice");
        const tx = await sendTransaction("transfer-pack", [Bob], [packId, Alice])
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Alice lists another pack for sale for FLOW on storefront", async () => {
        const Alice = await getAccountAddress("Alice")
        // get Bob's pack ids
        let alicesPacks = await executeScript("get-owned-packs", [Alice]);
        let packId = alicesPacks[0];
        let price = '1.5';

        // list for sale
        const tx = await sendTransaction("list-pack-for-sale-for-flow-on-nftstorefront", [Alice], [packId, price]);
        let data = tx.events[0].data;
        flowTokenPackSaleOfferResourceID = data.saleOfferResourceID;
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

    test("Bob buys a pack for FLOW and removes saleOffer item", async () => {

        const buyer = await getAccountAddress("Bob");
        const seller = await getAccountAddress("Alice");

        const saleOfferCountBefore = await executeScript("get-sale-offer-ids-in-nftstorefront", [seller]); 
        const tx = await sendTransaction("buy-pack-from-nftstorefront-with-flow-and-remove-saleoffer", [buyer], [flowTokenPackSaleOfferResourceID, seller]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);

        const saleOfferCountAfter = await executeScript("get-sale-offer-ids-in-nftstorefront", [seller]);
        expect(saleOfferCountBefore.length - saleOfferCountAfter.length).toBe(1);

        // check that the saleOffer can't accessed
        try {
            executeScript("get-saleoffer-nftid-from-storefront", [seller, flowTokenCardSaleOfferResourceID]);
            throw("can access saleoffer that should have been removed");
        } catch(e) {
            expect(e.toString()).toContain("can access saleoffer that should have been removed");
        }

        // check that saleOffer count has been reduced
    });

    test("Remove provisioned NFTStorefront from own account", async () => {
        const Bob = await getAccountAddress("Bob");
        const tx = await sendTransaction("remove-provisioned-nft-storefront", [Bob]);
        expect(tx.status).toBe(TX_SUCCESS_STATUS);
    });

});
