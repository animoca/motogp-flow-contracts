import SalesContract from 0xSalesContract

transaction(skuName: String, endTime: UInt64) {

    let adminRef: &SalesContract.Admin
    
    prepare(authAccount: AuthAccount) {
        self.adminRef = authAccount.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)!
    }
    execute {
        SalesContract.setEndTimeForSKU(adminRef: self.adminRef, name: skuName, endTime: endTime)
    }
}