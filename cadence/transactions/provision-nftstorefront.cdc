import NFTStorefront from 0xNFTStorefront

// This transaction installs the Storefront resource in an account.

//This file is originally named setup_Account.cdc:
//https://github.com/onflow/nft-storefront/blob/main/transactions/setup_account.cdc

transaction {
    prepare(acct: AuthAccount) {

        // If the account doesn't already have a Storefront
        if acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) == nil {

            // Create a new empty storefront
            let storefront <- NFTStorefront.createStorefront() as! @NFTStorefront.Storefront
            
            // Save it to the account
            acct.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)

            // Create a public capability for the storefront
            acct.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath, target: NFTStorefront.StorefrontStoragePath)
        }
    }
}