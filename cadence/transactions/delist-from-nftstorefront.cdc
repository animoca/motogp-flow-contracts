import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

transaction(saleOfferResourceID: UInt64) {
    let storefront: &MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontManager}

    prepare(acct: AuthAccount) {
        self.storefront = acct.borrow<&MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontManager}>(from: MotoGPNFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed MotoGPNFTStorefront.Storefront")
    }

    execute {
        self.storefront.removeSaleOffer(saleOfferResourceID: saleOfferResourceID)
    }
}