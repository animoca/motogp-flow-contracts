import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

transaction {
    prepare(acct: AuthAccount) {
        acct.unlink(MotoGPNFTStorefront.StorefrontPublicPath)
        let storefront <- acct.load<@AnyResource>(from: MotoGPNFTStorefront.StorefrontStoragePath)  
        destroy storefront
    }
}