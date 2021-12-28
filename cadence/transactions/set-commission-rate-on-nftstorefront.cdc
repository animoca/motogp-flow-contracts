import NFTStorefront from 0xNFTStorefront
import MotoGPAdmin from 0xMotoGPAdmin

transaction(commissionRate: UFix64) {
    let adminRef: &MotoGPAdmin.Admin
    prepare(acct: AuthAccount){
        self.adminRef = acct.borrow<&MotoGPAdmin.Admin>(from: /storage/motogpAdmin)!
    }
    execute{
        NFTStorefront.setCommissionRate(adminRef: self.adminRef, commissionRate: commissionRate)
    }
}