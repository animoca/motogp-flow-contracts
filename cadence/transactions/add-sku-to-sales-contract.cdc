import SalesContract from 0xSalesContract

transaction(startTime: UInt64, endTime: UInt64, name: String, payoutAddress: Address, packType: UInt64) {
    
    let adminRef: &SalesContract.Admin
    
    prepare(authAccount: AuthAccount) {
      self.adminRef = authAccount.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)
      ?? panic("Could not borrow admin resource")
    }

    execute {
        SalesContract.addSKU(adminRef: self.adminRef, startTime: startTime, endTime: endTime, name: name, payoutAddress: payoutAddress, packType: packType)
    }
}