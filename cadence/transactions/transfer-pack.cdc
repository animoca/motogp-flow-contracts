import MotoGPPack from 0xMotoGPPack
import NonFungibleToken from 0xNonFungibleToken

transaction(id: UInt64, recipient: Address) {
  let pack: @NonFungibleToken.NFT

  prepare(acct: AuthAccount) {
    // This is to support peer to peer pack transfers
    let packCollectionRef = acct.borrow<&MotoGPPack.Collection>(from: /storage/motogpPackCollection)
      ?? panic("Could not borrow the user's pack collection")
    self.pack <- packCollectionRef.withdraw(withdrawID: id)
  }

  execute {
    let recipientAccount = getAccount(recipient)
    let recipientPackCollectionRef = recipientAccount.getCapability(/public/motogpPackCollection)
        .borrow<&MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic}>()
        ?? panic("Could not borrow the public capability for the recipient's account")
    
    recipientPackCollectionRef.deposit(token: <- self.pack)

    log("Transfered the pack from the giver to the recipient")
  }
}