import FungibleToken from 0xFungibleToken
import NonFungibleToken from 0xNonFungibleToken
import REVV from 0xREVV
import MotoGPPack from 0xMotoGPPack
import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {
    let revvReceiver:Capability<&REVV.Vault{FungibleToken.Receiver}>
    let packProvider: Capability<&MotoGPPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &MotoGPNFTStorefront.Storefront

    prepare(account: AuthAccount) {
        self.revvReceiver = account.getCapability<&REVV.Vault{FungibleToken.Receiver}>(REVV.RevvReceiverPublicPath)!
        assert(self.revvReceiver.borrow() != nil, message: "Missing REVV receiver")

        // We need a provider capability, but one is not provideed by default so we create one if needed
        let packCollectionProviderPrivatePath = /private/packCollectionProvider
        if !account.getCapability<&MotoGPPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath).check() {
            account.link<&MotoGPPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath, target: /storage/motogpPackCollection)
        }

        self.packProvider = account.getCapability<&MotoGPPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath)!
        assert(self.packProvider.borrow() != nil, message: "Missing Pack Provider")

        self.storefront = account.borrow<&MotoGPNFTStorefront.Storefront>(from: MotoGPNFTStorefront.StorefrontStoragePath)
        ?? panic("Missing NFTStorefront Storefront")
    }

    execute {
        self.storefront.createSaleOffer(
            nftProviderCapability: self.packProvider,
            nftType: Type<@MotoGPPack.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@REVV.Vault>(),
            price: saleItemPrice,
            sellerReceiver: self.revvReceiver
        )
    }
}