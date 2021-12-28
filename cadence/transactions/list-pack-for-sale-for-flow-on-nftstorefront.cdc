import FungibleToken from 0xFungibleToken
import NonFungibleToken from 0xNonFungibleToken
import FlowToken from 0xFlowToken
import MotoGPPack from 0xMotoGPPack
import NFTStorefront from 0xNFTStorefront

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {
    let flowTokenReceiver:Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let packProvider: Capability<&MotoGPPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(account: AuthAccount) {
        self.flowTokenReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        assert(self.flowTokenReceiver.borrow() != nil, message: "Missing Flow Token receiver")

        // We need a provider capability, but one is not provideed by default so we create one if needed
        let packCollectionProviderPrivatePath = /private/packCollectionProvider
        if !account.getCapability<&MotoGPPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath).check() {
            account.link<&MotoGPPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath, target: /storage/motogpPackCollection)
        }

        self.packProvider = account.getCapability<&MotoGPPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath)!
        assert(self.packProvider.borrow() != nil, message: "Missing Pack Provider")

        self.storefront = account.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
        ?? panic("Missing NFTStorefront Storefront")
    }

    execute {
        self.storefront.createSaleOffer(
            nftProviderCapability: self.packProvider,
            nftType: Type<@MotoGPPack.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            price: saleItemPrice,
            sellerReceiver: self.flowTokenReceiver
        )
    }
}