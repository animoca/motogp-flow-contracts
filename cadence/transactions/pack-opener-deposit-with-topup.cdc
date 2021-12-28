import PackOpener from 0xPackOpener
import MotoGPCard from 0xMotoGPCard
import MotoGPPack from 0xMotoGPPack
import MotoGPTransfer from 0xMotoGPTransfer

// Transaction to provision a PackOpener collection and deposit a Pack into it, and top up if needed
//
transaction(id: UInt64, toAddress: Address) {

  var packCollectionRef: &MotoGPPack.Collection
  var packOpenerCollectionRef: &PackOpener.Collection

  prepare(acct: AuthAccount) {

    self.packCollectionRef = acct.borrow<&MotoGPPack.Collection>(from: /storage/motogpPackCollection)
    ?? panic("Could not borrow AuthAccount's Pack collection")

    self.packOpenerCollectionRef = acct.borrow<&PackOpener.Collection>(from: PackOpener.packOpenerStoragePath)
    ?? panic("Could not borrow AuthAccount's PackOpener collection")
  }

  execute {
    let pack <- self.packCollectionRef.withdraw(withdrawID: id) as! @MotoGPPack.NFT
    MotoGPTransfer.transferPackToPackOpenerCollection(pack: <- pack, toCollection: self.packOpenerCollectionRef, toAddress: toAddress)
  }
}