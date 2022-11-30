import MotoGPCard from 0xMotoGPCard

pub fun main(accountAddr: Address): [UInt64] {
  let acctCardCollectionRef = getAccount(accountAddr).getCapability(/public/motogpCardCollection)
            .borrow<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}>()
            ?? panic("Could not borrow the public capability for the recipient's account")
  return acctCardCollectionRef.getIDs()
}