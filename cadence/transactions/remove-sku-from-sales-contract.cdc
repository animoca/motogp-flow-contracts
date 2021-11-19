import SalesContract from 0xSalesContract

transaction(skuName: String) {

    let adminRef: &SalesContract.Admin
    
    prepare(authAccount: AuthAccount) {
        self.adminRef = authAccount.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)!
    }
    execute {
        SalesContract.removeSKU(adminRef: self.adminRef, skuName: skuName)
    }
}