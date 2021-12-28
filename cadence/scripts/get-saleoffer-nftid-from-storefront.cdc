import NFTStorefront from 0xNFTStorefront

pub fun main(address: Address, saleOfferResourceID: UInt64): UInt64 {
    let storefrontRef = getAccount(address)
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)
        .borrow() ?? panic("Could not borrow public storefront from address")
    
    return storefrontRef.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID)!.getDetails().nftID
}