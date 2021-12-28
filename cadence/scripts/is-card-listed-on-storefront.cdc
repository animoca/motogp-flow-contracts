import MotoGPCard from 0xMotoGPCard
import NFTStorefront from 0xNFTStorefront

pub fun main(address: Address, nftID: UInt64): Bool {
    
    let nftType = Type<@MotoGPCard.NFT>()
    
    let storefrontRef = getAccount(address)
    .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)
    .borrow() ?? panic("Could not borrow public storefront from address")
    
    let saleOfferIds = storefrontRef.getSaleOfferIDs()
    
    for saleOfferId in saleOfferIds {
        
        let nftDetails = storefrontRef.borrowSaleOffer(saleOfferResourceID: saleOfferId)!.getDetails()
        
        if nftDetails.nftType == nftType {
            if nftDetails.nftID == nftID {
                return true
            }
        }
    }
    
    return false
}