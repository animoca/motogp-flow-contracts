import SalesContract from 0xSalesContract

transaction(verificationKey: String) {

    let adminRef: &SalesContract.Admin
    
    prepare(authAccount: AuthAccount) {
        self.adminRef = authAccount.borrow<&SalesContract.Admin>(from: SalesContract.adminStoragePath)!
    }
    execute {
        SalesContract.setVerificationKey(adminRef: self.adminRef, verificationKey: verificationKey)
    }
}