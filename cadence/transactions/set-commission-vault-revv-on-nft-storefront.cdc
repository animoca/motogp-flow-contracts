import MotoGPNFTStorefront from 0xMotoGPNFTStorefront
import REVV from 0xREVV
import FungibleToken from 0xFungibleToken
import MotoGPAdmin from 0xMotoGPAdmin
import FlowToken from 0xFlowToken

transaction {
    let adminRef: &MotoGPAdmin.Admin
    let revvReceiverCap: Capability<&{FungibleToken.Receiver}>
    let flowTokenReceiverCap: Capability<&{FungibleToken.Receiver}>
    prepare(acct: AuthAccount) {

        if acct.getCapability<&FungibleToken.Vault{FungibleToken.Receiver}>(REVV.RevvReceiverPublicPath).borrow() == nil {
            acct.link<&{FungibleToken.Receiver}>(REVV.RevvReceiverPublicPath, target: REVV.RevvVaultStoragePath)
            //panic("inside the link clause")
        }

        self.revvReceiverCap = acct.getCapability<&{FungibleToken.Receiver}>(REVV.RevvReceiverPublicPath)! 
        if self.revvReceiverCap.borrow() == nil {
            panic("revvReceiverCap is null in tx")
        }
        self.flowTokenReceiverCap = acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)! 
        if self.flowTokenReceiverCap.borrow() == nil {
            panic("flowTokenReceiverCap is null in tx")
        }

        self.adminRef = acct.borrow<&MotoGPAdmin.Admin>(from: /storage/motogpAdmin)!
    }

    execute {
       MotoGPNFTStorefront.setCommissionReceiver(adminRef: self.adminRef, vaultType: Type<@REVV.Vault>(), commissionReceiver: self.revvReceiverCap)
       MotoGPNFTStorefront.setCommissionReceiver(adminRef: self.adminRef, vaultType: Type<@FlowToken.Vault>(), commissionReceiver: self.flowTokenReceiverCap)
    }
}