import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

transaction(storefrontAddress: Address, saleOfferResourceID: UInt64) {
    let storefront: &MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontPublic}

    prepare(acct: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
        .getCapability<&MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontPublic}>(MotoGPNFTStorefront.StorefrontPublicPath)!.borrow()
        ?? panic("Could not borrow Storefront from provided address")
    }

    execute {
        self.storefront.cleanup(saleOfferResourceID: saleOfferResourceID)
    }
    
}