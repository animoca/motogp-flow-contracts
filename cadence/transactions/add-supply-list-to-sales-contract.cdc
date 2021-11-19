import SalesContract from 0xSalesContract

transaction(name: String, supplyList:[UInt64]) {
    let adminRef: &SalesContract.Admin
    
    prepare(authAccount: AuthAccount) {
      self.adminRef = authAccount.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)
      ?? panic("Could not borrow admin resource")
    }

    execute {
        SalesContract.increaseSupplyForSKU(adminRef: self.adminRef, name: name, supplyList: supplyList)
    }
}