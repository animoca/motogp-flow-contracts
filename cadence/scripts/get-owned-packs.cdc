import MotoGPPack from 0xMotoGPPack

pub fun main(accountAddr: Address): [UInt64] {
  let acctPackCollectionRef = getAccount(accountAddr).getCapability(/public/motogpPackCollection)
            .borrow<&MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic}>()
            ?? panic("Could not borrow the public capability for the recipient's account")
  return acctPackCollectionRef.getIDs()
}
