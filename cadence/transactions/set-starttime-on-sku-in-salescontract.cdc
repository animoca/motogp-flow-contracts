import SalesContract from 0xSalesContract

transaction(skuName: String, startTime: UInt64) {

    let adminRef: &SalesContract.Admin
    
    prepare(authAccount: AuthAccount) {
        self.adminRef = authAccount.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)!
    }
    execute {
        SalesContract.setStartTimeForSKU(adminRef: self.adminRef, name: skuName, startTime: startTime)
    }
}