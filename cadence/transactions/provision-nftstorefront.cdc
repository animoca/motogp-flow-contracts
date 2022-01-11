import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

// This transaction installs the Storefront resource in an account.

//This file is originally named setup_Account.cdc:
//https://github.com/onflow/nft-storefront/blob/main/transactions/setup_account.cdc

transaction {
    prepare(acct: AuthAccount) {

        // If the account doesn't already have a Storefront
        if acct.borrow<&MotoGPNFTStorefront.Storefront>(from: MotoGPNFTStorefront.StorefrontStoragePath) == nil {

            // Create a new empty storefront
            let storefront <- MotoGPNFTStorefront.createStorefront() as! @MotoGPNFTStorefront.Storefront
            
            // Save it to the account
            acct.save(<-storefront, to: MotoGPNFTStorefront.StorefrontStoragePath)

            // Create a public capability for the storefront
            acct.link<&MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontPublic}>(MotoGPNFTStorefront.StorefrontPublicPath, target: MotoGPNFTStorefront.StorefrontStoragePath)
        }
    }
}