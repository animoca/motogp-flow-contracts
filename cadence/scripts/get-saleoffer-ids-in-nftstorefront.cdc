import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

pub fun main(address: Address): [UInt64] {
    let storefrontRef = getAccount(address).getCapability<&MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontPublic}>(
            MotoGPNFTStorefront.StorefrontPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public storefront from address")
    
    return storefrontRef.getSaleOfferIDs()
}