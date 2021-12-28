import MotoGPAdmin from 0xMotoGPAdmin
import PackOpener from 0xPackOpener
import MotoGPCard from 0xMotoGPCard
import MotoGPTransfer from 0xMotoGPTransfer

transaction(recipientAddress: Address, packId: UInt64, cardIDs: [UInt64], serials: [UInt64]) {

  let adminRef: &MotoGPAdmin.Admin
  let packOpenerCollectionRef: &PackOpener.Collection{PackOpener.IPackOpenerPublic}

  prepare(acct: AuthAccount) {
    self.adminRef = acct.borrow<&MotoGPAdmin.Admin>(from: /storage/motogpAdmin)
    ?? panic("Could not borrow AuthAccount's Admin reference")

    self.packOpenerCollectionRef = getAccount(recipientAddress).getCapability(PackOpener.packOpenerPublicPath)!.borrow<&PackOpener.Collection{PackOpener.IPackOpenerPublic}>()
    ?? panic("Could not borrow recipient's PackOpener collection")
  }

  execute {
    self.packOpenerCollectionRef.openPack(adminRef: self.adminRef, id: packId, cardIDs: cardIDs, serials: serials)
    MotoGPTransfer.topUpFlowForAccount(adminRef: self.adminRef, toAddress: recipientAddress)
  }
}