import FungibleToken from 0xFungibleToken
import NonFungibleToken from 0xNonFungibleToken
import FlowToken from 0xFlowToken
import MotoGPCard from 0xMotoGPCard
import MotoGPNFTStorefront from 0xMotoGPNFTStorefront

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {
    let flowTokenReceiver:Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let cardProvider: Capability<&MotoGPCard.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &MotoGPNFTStorefront.Storefront

    prepare(account: AuthAccount) {
        
        self.flowTokenReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        assert(self.flowTokenReceiver.borrow() != nil, message: "Missing FlowToken receiver")

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
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            price: saleItemPrice,
            sellerReceiver: self.flowTokenReceiver
        )
    }
}