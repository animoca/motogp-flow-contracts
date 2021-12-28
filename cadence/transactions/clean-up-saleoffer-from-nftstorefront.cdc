import NFTStorefront from 0xNFTStorefront

transaction(storefrontAddress: Address, saleOfferResourceID: UInt64) {
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}

    prepare(acct: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)!.borrow()
        ?? panic("Could not borrow Storefront from provided address")
    }

    execute {
        self.storefront.cleanup(saleOfferResourceID: saleOfferResourceID)
    }
    
}