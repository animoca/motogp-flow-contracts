import SalesContract from 0xSalesContract

transaction(skuName: String, price: UFix64) {

    let adminRef: &SalesContract.Admin
    
    prepare(authAccount: AuthAccount) {
        self.adminRef = authAccount.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)!
    }
    execute {
        SalesContract.setPriceForSKU(adminRef: self.adminRef, name: skuName, price: price)
    }
}