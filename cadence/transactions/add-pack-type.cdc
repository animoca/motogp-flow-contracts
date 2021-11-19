import MotoGPAdmin from 0xMotoGPAdmin

transaction(packType: UInt64, numberOfCards: UInt64) {
  prepare(acct: AuthAccount) {
      let adminRef = acct.borrow<&MotoGPAdmin.Admin>(from: /storage/motogpAdmin)
      ?? panic("Could not borrow admin resource")
      
      adminRef.addPackType(packType: packType, numberOfCards: numberOfCards)
  }

  execute {
      
  }
}