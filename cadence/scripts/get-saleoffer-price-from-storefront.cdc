import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

pub fun main(address: Address, saleOfferResourceID: UInt64): UFix64 {
    let storefrontRef = getAccount(address)
        .getCapability<&MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontPublic}>(MotoGPNFTStorefront.StorefrontPublicPath)
        .borrow() ?? panic("Could not borrow public storefront from address")
    
    return storefrontRef.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID)!.getDetails().salePrice
}