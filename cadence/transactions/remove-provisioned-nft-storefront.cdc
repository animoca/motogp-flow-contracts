import NFTStorefront from 0xNFTStorefront

transaction {
    prepare(acct: AuthAccount) {
        acct.unlink(NFTStorefront.StorefrontPublicPath)
        let storefront <- acct.load<@AnyResource>(from: NFTStorefront.StorefrontStoragePath)  
        destroy storefront
    }
}