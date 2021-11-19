import SalesContract from 0xSalesContract

transaction(skuName: String, maxPerBuyer: UInt64) {

    let adminRef: &SalesContract.Admin
    
    prepare(authAccount: AuthAccount) {
        self.adminRef = authAccount.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)!
    }
    execute {
        SalesContract.setMaxPerBuyerForSKU(adminRef: self.adminRef, name: skuName, maxPerBuyer: maxPerBuyer)
    }
}