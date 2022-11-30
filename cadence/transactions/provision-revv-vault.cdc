import FungibleToken from 0xFungibleToken
import REVV from 0xREVV

transaction {

    prepare(signer: AuthAccount) {

        // It's OK if the account already has a Vault, but we don't want to replace it
        if(signer.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath) != nil) {
            return
        }
        
        // Create a new Vault and put it in storage
        signer.save(<-REVV.createEmptyVault(), to: REVV.RevvVaultStoragePath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&REVV.Vault{FungibleToken.Receiver}>(
            REVV.RevvReceiverPublicPath,
            target: REVV.RevvVaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&REVV.Vault{FungibleToken.Balance}>(
            REVV.RevvBalancePublicPath,
            target: REVV.RevvVaultStoragePath
        )

    }
}