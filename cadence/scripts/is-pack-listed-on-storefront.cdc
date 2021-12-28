import MotoGPPack from 0xMotoGPPack
import NFTStorefront from 0xNFTStorefront

pub fun main(address: Address, nftID: UInt64): Bool {
    let nftType = Type<@MotoGPPack.NFT>() // Type can't be passed as argument

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