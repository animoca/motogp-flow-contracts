import FungibleToken from 0xFungibleToken
import SalesContract from 0xSalesContract

transaction(amount: UFix64) {

    let adminRef: &SalesContract.Admin
    var vaultRef: &FungibleToken.Vault
    
    prepare(acct: AuthAccount) {
        self.adminRef = acct.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)!
        self.vaultRef = acct.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)!
    }
    execute {
        let tempVault <- SalesContract.withdrawFlow(adminRef: self.adminRef, amount: amount)
        self.vaultRef.deposit(from: <- tempVault)
    }
}