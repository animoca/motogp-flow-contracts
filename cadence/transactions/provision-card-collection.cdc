import MotoGPCard from 0xMotoGPCard
import MotoGPPack from 0xMotoGPPack

transaction {

  prepare(acct: AuthAccount) {
    
    if acct.borrow<&MotoGPCard.Collection>(from: /storage/motogpCardCollection) == nil {

      let cardCollection <- MotoGPCard.createEmptyCollection()
            
      acct.save(<-cardCollection, to: /storage/motogpCardCollection)

      acct.link<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}>(/public/motogpCardCollection, target: /storage/motogpCardCollection)
    
    }

  }

  execute {
    
  }
}
