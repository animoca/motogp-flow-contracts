import REVV from 0xREVV
import FungibleToken from 0xFungibleToken

transaction(to: Address, amount: UFix64) {
    let vaultRef: &REVV.Vault
    let receiverRef: &REVV.Vault{FungibleToken.Receiver}
    prepare(acct: AuthAccount) {
        self.vaultRef = acct.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath) ?? panic("Could not borrow a reference to the vault resource")
        self.receiverRef = getAccount(to).getCapability(REVV.RevvReceiverPublicPath)!
            .borrow<&REVV.Vault{FungibleToken.Receiver}>() ?? panic("Could not borrow a reference to Receiver")   
    }
    
    execute {
        let tempVault <- self.vaultRef.withdraw(amount: amount) as! @REVV.Vault
        self.receiverRef.deposit(from: <- tempVault)
    }
}