import FungibleToken from 0xFungibleToken
import NonFungibleToken from 0xNonFungibleToken
import MotoGPPack from 0xMotoGPPack
import MotoGPNFTStorefront from 0xMotoGPNFTStorefront
import REVV from 0xREVV
import Debug from 0xDebug

transaction(saleOfferResourceID: UInt64, storefrontAddress: Address) {
    let paymentVault: @FungibleToken.Vault
    let packCollection: &MotoGPPack.Collection{NonFungibleToken.CollectionPublic}
    let storefront: &MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontPublic}
    let saleOffer: &MotoGPNFTStorefront.SaleOffer{MotoGPNFTStorefront.SaleOfferPublic}

    prepare(acct: AuthAccount) {

        self.storefront = getAccount(storefrontAddress)
        .getCapability<&MotoGPNFTStorefront.Storefront{MotoGPNFTStorefront.StorefrontPublic}>(MotoGPNFTStorefront.StorefrontPublicPath)!.borrow()
        ?? panic("Could not borrow Storefront from provided address")

        self.saleOffer = self.storefront.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID) ?? panic("No Offer with that ID in Storefront")


        var price:UFix64 = self.saleOffer.getDetails().salePrice

        Debug.Log(message: "price".concat(price.toString()))

        let revvVault = acct.borrow<&REVV.Vault>(from: /storage/revvVault) ?? panic("Cannot borrow REVV vault from acct storage")

        self.paymentVault <- revvVault.withdraw(amount: price)

        self.packCollection = acct.borrow<&MotoGPPack.Collection{NonFungibleToken.CollectionPublic}>(from: /storage/motogpPackCollection)
        ?? panic("Cannot borrow NFT collection receiver from account")
        
    }

    execute {
        
        let item <- self.saleOffer.accept(
            payment: <-self.paymentVault
        )

        self.packCollection.deposit(token: <-item)
        
    }
    
}