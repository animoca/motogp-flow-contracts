import FungibleToken from 0xFungibleToken
import NonFungibleToken from 0xNonFungibleToken
import REVV from 0xREVV
import MotoGPCard from 0xMotoGPCard
import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {
    let revvReceiver:Capability<&REVV.Vault{FungibleToken.Receiver}>
    let cardProvider: Capability<&MotoGPCard.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &MotoGPNFTStorefront.Storefront

    prepare(account: AuthAccount) {
        
        self.revvReceiver = account.getCapability<&REVV.Vault{FungibleToken.Receiver}>(REVV.RevvReceiverPublicPath)!
        assert(self.revvReceiver.borrow() != nil, message: "Missing REVV receiver")

        // We need a provider capability, but one is not provideed by default so we create one if needed
        let cardCollectionProviderPrivatePath = /private/cardCollectionProvider
        if !account.getCapability<&MotoGPCard.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(cardCollectionProviderPrivatePath).check() {
            account.link<&MotoGPCard.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(cardCollectionProviderPrivatePath, target: /storage/motogpCardCollection)
        }

        self.cardProvider = account.getCapability<&MotoGPCard.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(cardCollectionProviderPrivatePath)!
        assert(self.cardProvider.borrow() != nil, message: "Missing card Provider")

        self.storefront = account.borrow<&MotoGPNFTStorefront.Storefront>(from: MotoGPNFTStorefront.StorefrontStoragePath)
        ?? panic("Missing NFTStorefront Storefront")
        
    }

    execute {
        self.storefront.createSaleOffer(
            nftProviderCapability: self.cardProvider,
            nftType: Type<@MotoGPCard.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@REVV.Vault>(),
            price: saleItemPrice,
            sellerReceiver: self.revvReceiver
        )
        
    }
}