import NFTStorefront from 0xNFTStorefront
import MotoGPPack from 0xMotoGPPack

pub fun main(address: Address): [UInt64] {
    
    let storefrontRef = getAccount(address)
    .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)
    .borrow() ?? panic("Could not borrow public storefront from address")
    
    
    let saleOfferIds = storefrontRef.getSaleOfferIDs()
    let packIds:[UInt64] = []
    for saleOfferId in saleOfferIds {
        let nftDetails = storefrontRef.borrowSaleOffer(saleOfferResourceID: saleOfferId)!.getDetails()
        if nftDetails.nftType == Type<@MotoGPPack.NFT>() {
            packIds.append(nftDetails.nftID)
        }
    }
    
    return packIds
}