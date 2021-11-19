transaction {

  prepare(acct: AuthAccount) {
    let admin <- acct.load<@AnyResource>(from: /storage/salesContractAdmin)  
    destroy admin
  }

  execute {
    
  }
}