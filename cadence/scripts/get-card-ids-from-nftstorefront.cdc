import NFTStorefront from 0xNFTStorefront
import MotoGPCard from 0xMotoGPCard

pub fun main(address: Address): [UInt64] {
    
    let storefrontRef = getAccount(address)
    .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)
    .borrow() ?? panic("Could not borrow public storefront from address")
    
    
    let saleOfferIds = storefrontRef.getSaleOfferIDs()
    let cardIds:[UInt64] = []
    for saleOfferId in saleOfferIds {
        let nftDetails = storefrontRef.borrowSaleOffer(saleOfferResourceID: saleOfferId)!.getDetails()
        if nftDetails.nftType == Type<@MotoGPCard.NFT>() {
            cardIds.append(nftDetails.nftID)
        }
    }
    
    return cardIds
}