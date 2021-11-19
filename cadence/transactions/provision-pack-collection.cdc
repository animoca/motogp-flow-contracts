import MotoGPPack from 0xMotoGPPack

transaction {

  prepare(acct: AuthAccount) {
    
    if acct.borrow<&MotoGPPack.Collection>(from: /storage/motogpPackCollection) == nil {

      let packCollection <- MotoGPPack.createEmptyCollection()
            
      acct.save(<-packCollection, to: /storage/motogpPackCollection)

      acct.link<&MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic}>(/public/motogpPackCollection, target: /storage/motogpPackCollection)    
    }

  }

  execute {
    
  }
}