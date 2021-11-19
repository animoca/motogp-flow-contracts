import SalesContract from 0xSalesContract
import FungibleToken from 0xFungibleToken
import MotoGPPack from 0xMotoGPPack

transaction(signature: String, nonce: UInt32, packType: UInt64, skuName: String, recipient: Address) {

    var paymentVaultRef: &FungibleToken.Vault
    var recipientCollectionRef: &MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic}

    prepare(authAccount: AuthAccount) {
        self.paymentVaultRef = authAccount.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow a reference to the buyer's vault")
        if authAccount.borrow<&MotoGPPack.Collection>(from: /storage/motogpPackCollection) == nil {
            let packCollection <- MotoGPPack.createEmptyCollection()
            authAccount.save(<-packCollection, to: /storage/motogpPackCollection)
            authAccount.link<&MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic, MotoGPPack.IPackCollectionAdminAccessible}>(/public/motogpPackCollection, target: /storage/motogpPackCollection)
        }
        self.recipientCollectionRef = getAccount(recipient).getCapability(/public/motogpPackCollection).borrow<&MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic}>()
        ?? panic("Could not borrow the public capability for the recipient's account")
    }
    execute {
        SalesContract.buyPack(  signature: signature, 
                                nonce: nonce, 
                                packType: packType, 
                                skuName: skuName, 
                                recipient: recipient, 
                                paymentVaultRef: self.paymentVaultRef, 
                                recipientCollectionRef: self.recipientCollectionRef)
    }
}