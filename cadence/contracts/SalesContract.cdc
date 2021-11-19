import MotoGPAdmin from  0xMotoGPAdmin
import MotoGPPack from 0xMotoGPPack
import NonFungibleToken from 0xNonFungibleToken
import FlowToken from 0xFlowToken
import FungibleToken from 0xFungibleToken
import MotoGPTransfer from 0xMotoGPTransfer

// The SalesContract role is to enable on-chain sales of MotoGP packs.
// Users buy directly from the buyPack method and get the pack deposited into their collection, if all conditions are met.
// The contract admin manages sales by adding SKUs to the contract. A SKU is equivalent to a drop.
//
// Each SKU has a list of serial numbers (equivalent to print numbers), and when the user buys a pack, a serial is selected from the SKUs serial list,
// and removed from the list. To make the serial selection hard to predict (pseuo-random) we employ a logic discussed further below.
//
// The buyPack method takes a signature as one of its arguments. This signature is generated when the user requests to buy a pack via the MotoGP web site. 
// The user calls the MotoGP backend signing service. Using a private key, the signing service creates a signature which includes the user's address, a nonce unique to the address which is read from the SalesContract, and the pack type.
// The signing service then sends the signature back to user the user, who then send a transaction including the signature to the SalesContract to buy pack.
// Inside the buyPack method, the signature is verifying using a public key which is a field on the contract, and that only the admin can set. 
// The key is set on the contract, rather than the account, to ensure it is only used for this contract.
//
// After the signature has been verified, the first byte is read from the signature and an index is created from it, which is used to 
// select a serial from the serial list. That serial is then removed, and a pack is minted and deposited into the users collection.
//
// The user's payment for packs comes from a Flow vault submitted in the buyPack transaction. The payment is deposited into a Flow vault at an address set on the SKU.
//
pub contract SalesContract {

    pub fun getVersion(): String {
        return "0.1.8"
    }

    pub let adminStoragePath: StoragePath
    access(contract) let skuMap: {String : SKU}
    access(contract) let nonceMap: {Address : UInt64}
    access(contract) var verificationKey: String
    access(contract) let serialMap: { UInt64 : { UInt64 : Bool}} // { packType : { serial: true/false } 

    pub struct SKU {
        access(contract) var startTime: UInt64;
        access(contract) var endTime: UInt64;
        access(contract) var totalSupply: UInt64;
        access(contract) var serialList: [UInt64]
        access(contract) let buyerCountMap: { Address: UInt64 }
        access(contract) var price: UFix64
        access(contract) var maxPerBuyer: UInt64
        access(contract) var payoutAddress: Address
        access(contract) var packType: UInt64
        init(startTime: UInt64, endTime: UInt64, payoutAddress: Address, packType: UInt64){
            self.startTime = startTime
            self.endTime = endTime 
            self.serialList = []
            self.buyerCountMap = {}
            self.totalSupply = UInt64(0)
            self.maxPerBuyer = UInt64(1)
            self.price = UFix64(0.0)
            self.payoutAddress = payoutAddress
            self.packType = packType
        }

        access(contract) fun setStartTime(startTime: UInt64) {
            self.startTime = startTime
        }

        access(contract) fun setEndTime(endTime: UInt64) {
            self.endTime = endTime
        }

        access(contract) fun setPrice(price: UFix64){
            self.price = price
        }

        access(contract) fun setMaxPerBuyer(maxPerBuyer: UInt64) {
            self.maxPerBuyer = maxPerBuyer
        }

        access(contract) fun setPayoutAddress(payoutAddress: Address) {
            self.payoutAddress = payoutAddress
        }

        access(contract) fun increaseSupply(supplyList: [UInt64]){
            let oldTotalSupply = UInt64(self.serialList.length)
            self.serialList = self.serialList.concat(supplyList)
            self.totalSupply =  UInt64(supplyList.length) + oldTotalSupply
            

            if !SalesContract.serialMap.containsKey(self.packType) {
                SalesContract.serialMap[self.packType] = {};
            }
            let statusMap = SalesContract.serialMap[self.packType]!

            var index: UInt64 = UInt64(0);
            while index < UInt64(supplyList.length) {
                let serial = supplyList[index]
                if statusMap.containsKey(serial) && statusMap[serial]! == true {
                    let msg = "Serial ".concat(serial.toString()).concat(" for packtype").concat(self.packType.toString()).concat(" is already added")
                    panic(msg)
                }
                SalesContract.serialMap[self.packType]!.insert(key: serial, true)
                index = index + UInt64(1)
            }
        }
    }
    pub fun isCurrentSKU(name: String): Bool {
        let sku = self.skuMap[name]!
        let now = UInt64(getCurrentBlock().timestamp)
        if sku.startTime <= now && sku.endTime > now {
            return true
        }
        
        return false
    }

    pub fun getStartTimeForSKU(name: String): UInt64 {
        return self.skuMap[name]!.startTime
    }

    pub fun getEndTimeForSKU(name: String): UInt64 {
        return self.skuMap[name]!.endTime
    }

    pub fun getTotalSupplyForSKU(name: String): UInt64 {
        return self.skuMap[name]!.totalSupply
    }

    pub fun getRemainingSupplyForSKU(name: String): UInt64 {
        return UInt64(self.skuMap[name]!.serialList.length)
    }

    pub fun getBuyCountForAddress(skuName: String, recipient: Address): UInt64 {
        return self.skuMap[skuName]!.buyerCountMap[recipient] ?? UInt64(0)
    }

    pub fun getPriceForSKU(name: String): UFix64 {
        return self.skuMap[name]!.price
    }

    pub fun getMaxPerBuyerForSKU(name: String): UInt64 {
        return self.skuMap[name]!.maxPerBuyer
    }

    pub fun getActiveSKUs(): [String] {
        let activeSKUs:[String] = []
        let keys = self.skuMap.keys
        var index = UInt64(0)
        while index < UInt64(keys.length) {
            let key = keys[index]!
            let sku = self.skuMap[key]!
            let now = UInt64(getCurrentBlock().timestamp)
            if sku.startTime <= now { // SKU has started
                if sku.endTime > now  {// SKU hasn't ended
                    activeSKUs.append(key)
                }
            }
            index = index + UInt64(1)
        }
        return activeSKUs;
    }

    pub fun getAllSKUs(): [String] {
        return self.skuMap.keys
    }

    pub fun removeSKU(adminRef: &Admin, skuName: String) {
        self.skuMap.remove(key: skuName)
    }

    pub resource Admin {}
    
    pub fun setVerificationKey(adminRef: &Admin, verificationKey: String) {
        pre {
            adminRef != nil : "adminRef is nil."
        }
        self.verificationKey = verificationKey;
    }

    access(contract) fun isValidSignature(signature: String, message: String): Bool {
        
        let pk = PublicKey(
            publicKey: self.verificationKey.decodeHex(),
            signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
        )

        let isValid = pk.verify(
            signature: signature.decodeHex(),
            signedData: message.utf8,
            domainSeparationTag: "FLOW-V0.0-user",
            hashAlgorithm: HashAlgorithm.SHA3_256
        )
        return isValid
    }
    
    pub fun getNonce(address: Address): UInt64 {
        return self.nonceMap[address] ?? 0 as UInt64
    }

    pub fun isActiveSKU(name: String): Bool {
            let sku = self.skuMap[name]!
            let now = UInt64(getCurrentBlock().timestamp)
            if sku.startTime <= now { // SKU has started
                if sku.endTime > now  {// SKU hasn't ended
                    return true
                }
            }
            return false
    }

    pub fun convertAddressToString(address: Address): String {
        let EXPECTED_ADDRESS_LENGTH = 18
        var addrStr = address.toString() //Cadence shortens addresses starting with 0, so 0x0123 becomes 0x123
        if addrStr.length == EXPECTED_ADDRESS_LENGTH {
            return addrStr
        }
        let prefix = addrStr.slice(from: 0, upTo: 2)
        var suffix = addrStr.slice(from: 2, upTo: addrStr.length)
        
        let steps = EXPECTED_ADDRESS_LENGTH - addrStr.length
        var index = 0
        while index < steps {
            suffix = "0".concat(suffix) 
            index = index + 1
        }
        
        addrStr = prefix.concat(suffix)
        if addrStr.length != EXPECTED_ADDRESS_LENGTH {
            panic("Padding address String is wrong length")
        }
        return addrStr
    }

    pub fun buyPack(signature: String, 
                    nonce: UInt32, 
                    packType: UInt64, 
                    skuName: String, 
                    recipient: Address, 
                    paymentVaultRef: &FungibleToken.Vault, 
                    recipientCollectionRef: &MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic}) {

        pre {
            paymentVaultRef.balance >= self.skuMap[skuName]!.price : "paymentVaultRef's balance is lower than price"
            self.isActiveSKU(name: skuName) == true : "SKU is not active"
            self.getRemainingSupplyForSKU(name: skuName) > UInt64(0) : "No remaining supply for SKU"
            self.skuMap[skuName]!.price >= UFix64(0.0) : "Price is zero. Admin needs to set the price"
            self.skuMap[skuName]!.packType == packType : "Supplied packType doesn't match SKU packType"
        }                

        post {
            self.nonceMap[recipient]! == before(self.nonceMap[recipient] ?? UInt64(0)) + UInt64(1)  : "Nonce hasn't increased by one"
            self.skuMap[skuName]!.buyerCountMap[recipient]! == before(self.skuMap[skuName]!.buyerCountMap[recipient] ?? UInt64(0)) + UInt64(1) : "buyerCountMap hasn't increased by one"
            self.skuMap[skuName]!.buyerCountMap[recipient]! <= self.skuMap[skuName]!.maxPerBuyer : "Max pack purchase count per buyer exceeded"
            paymentVaultRef.balance == before(paymentVaultRef.balance) - self.skuMap[skuName]!.price : "Decrease in buyer vault balance doesn't match the price"
        }

        let sku = self.skuMap[skuName]!

        let recipientStr = self.convertAddressToString(address: recipient)

        let message = skuName.concat(recipientStr).concat(nonce.toString()).concat(packType.toString());
        let isValid = self.isValidSignature(signature: signature, message: message)
        if isValid == false {
            panic("Signature isn't valid");
        }

        let payment <- paymentVaultRef.withdraw(amount: sku.price) // Will panic if not enough $
        let vault <- payment as! @FlowToken.Vault // Will panic if can't be cast

        let payoutRecipient = getAccount(sku.payoutAddress)
        let payoutReceiver = payoutRecipient.getCapability(/public/flowTokenReceiver)
                            .borrow<&FlowToken.Vault{FungibleToken.Receiver}>()
                            ?? panic("Could not borrow a reference to the payout receiver")
        payoutReceiver.deposit(from: <-vault)

        if self.nonceMap.containsKey(recipient) {
            let oldNonce: UInt64 = self.nonceMap[recipient]!
            let baseMessage = "Nonce ".concat(nonce.toString()).concat(" for ").concat(recipient.toString())
            if oldNonce >= UInt64(nonce) {
                panic(baseMessage.concat(" already used"));
            }
            if (oldNonce + 1 as UInt64) < UInt64(nonce) {
                panic(baseMessage.concat(" is not next nonce"));
            }
            self.nonceMap[recipient] =  oldNonce + UInt64(1)
        } else {
            self.nonceMap[recipient] = UInt64(1)
        }

        // Use first byte of message as index to select from supply.
        var index = UInt64(signature.decodeHex()[0]!)
        
        // Ensure the index falls within the serial list
        index = index % UInt64(sku.serialList.length)

        // **Remove** the selected packNumber from the packNumber list.
        // By removing the item, we ensure that even if same index is selected again in next tx, it will refer to another item.
        let packNumber = sku.serialList.remove(at: index);

        // Mint a pack
        let nft <- MotoGPPack.createPack(packNumber: packNumber, packType: packType);

        // Update recipient's buy-count
       
        if sku.buyerCountMap.containsKey(recipient) {
            let oldCount = sku.buyerCountMap[recipient]!
            sku.buyerCountMap[recipient] = UInt64(oldCount) + UInt64(1)
            self.skuMap[skuName] = sku
        } else {
            sku.buyerCountMap[recipient] = UInt64(1)
            self.skuMap[skuName] = sku
        }

        // We deposit the purchased pack into a temporary collection, to be able to topup the buyer's Flow/storage using the MotoGPTransfer contract
        let tempCollection <- MotoGPPack.createEmptyCollection()
        tempCollection.deposit(token: <- nft); 

        // We transfer the pack using the MotoGPTransfer contract, to do Flow/storage topup for recipient
        MotoGPTransfer.transferPacks(fromCollection: <- tempCollection, toCollection: recipientCollectionRef, toAddress: recipient);    
    }

    pub fun setSerialStatusInPackTypeMap(adminRef: &Admin, packType: UInt64, serial: UInt64, value: Bool) {
        pre {
            adminRef != nil : "adminRef is nil"
        }
        if SalesContract.serialMap.containsKey(packType) {
            SalesContract.serialMap[packType]!.insert(key: serial, value)
        }
    }

    pub fun addSKU(adminRef: &Admin, startTime: UInt64, endTime: UInt64, name: String, payoutAddress: Address, packType: UInt64) {
        pre {
            adminRef != nil : "adminRef is nil"
        }
        let sku = SKU(startTime: startTime, endTime: endTime, payoutAddress: payoutAddress, packType: packType);
        self.skuMap.insert(key: name, sku)
    }

    pub fun increaseSupplyForSKU(adminRef: &Admin, name: String, supplyList: [UInt64]) {
        pre {
            adminRef != nil : "adminRef is nil"
        }
        let sku = self.skuMap[name]!
        sku.increaseSupply(supplyList: supplyList)
        self.skuMap[name] = sku
    }

    pub fun setMaxPerBuyerForSKU(adminRef: &Admin, name: String, maxPerBuyer: UInt64) {
        pre {
            adminRef != nil : "adminRef is nil"
        }
        let sku = self.skuMap[name]!
        sku.setMaxPerBuyer(maxPerBuyer: maxPerBuyer)
        self.skuMap[name] = sku
    }

    pub fun setPriceForSKU(adminRef: &Admin, name: String, price: UFix64) {
        pre {
            adminRef != nil : "adminRef is nil"
        }
        let sku = self.skuMap[name]!
        sku.setPrice(price: price)
        self.skuMap[name] = sku
    }

    pub fun setEndTimeForSKU(adminRef: &Admin, name: String, endTime: UInt64) {
        pre {
            adminRef != nil : "adminRef is nil"
        }
        let sku = self.skuMap[name]!
        sku.setEndTime(endTime: endTime)
        self.skuMap[name] = sku
    }

    pub fun setStartTimeForSKU(adminRef: &Admin, name: String, startTime: UInt64) {
        pre {
            adminRef != nil : "adminRef is nil"
        }
        let sku = self.skuMap[name]!
        sku.setStartTime(startTime: startTime)
        self.skuMap[name] = sku
    }

    pub fun setPayoutAddressForSKU(adminRef: &Admin, name: String, payoutAddress: Address) {
        pre {
            adminRef != nil : "adminRef is nil"
        }
        let sku = self.skuMap[name]!
        sku.setPayoutAddress(payoutAddress: payoutAddress)
        self.skuMap[name] = sku
    }

    pub fun getSKU(name: String): SKU {
        return self.skuMap[name]!
    }

    pub fun getVerificationKey(): String {
        return self.verificationKey
    }

    init(){
        self.adminStoragePath = /storage/salesContractAdmin
        self.verificationKey = ""
        self.account.save(<- create Admin(), to: self.adminStoragePath)
        self.skuMap = {}
        self.nonceMap = {}
        self.serialMap = {}
    }
}