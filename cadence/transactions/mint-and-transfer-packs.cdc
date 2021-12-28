import MotoGPAdmin from 0xMotoGPAdmin
import MotoGPPack from 0xMotoGPPack

transaction(recipient: Address, packType: UInt64, packNumbers: [UInt64]) {

    let adminPackCollectionRef: &MotoGPPack.Collection
    let packIds: [UInt64]

    prepare(acct: AuthAccount) {

        self.packIds = []

        var packId = MotoGPPack.totalSupply; 

        let minterRef = acct.borrow<&MotoGPAdmin.Admin>(from: /storage/motogpAdmin)
            ?? panic("Could not borrow the minter reference from the admin")
        
        minterRef.mintPacks(packType: packType, numberOfPacks: UInt64(packNumbers.length), packNumbers: packNumbers)

        var lastPackId = MotoGPPack.totalSupply - 1 as UInt64

        while packId <= lastPackId {
            self.packIds.append(packId)
            packId = packId + 1 as UInt64
        }

        self.adminPackCollectionRef = acct.borrow<&MotoGPPack.Collection>(from: /storage/motogpPackCollection)
            ?? panic("Could not borrow the admin's pack collection")
    }

    execute {
        let recipientAccount = getAccount(recipient)

        let recipientPackCollectionRef = recipientAccount.getCapability(/public/motogpPackCollection)
            .borrow<&MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic}>()
                ?? panic("Could not borrow the public capability for the recipient's account")
        
        for id in self.packIds {
            let packData = self.adminPackCollectionRef.borrowPack(id: id) ?? panic("Could not borrow the pack from admin's collection")
            
            if packData.packInfo.packType == packType && packNumbers.contains(packData.packInfo.packNumber) {
                let pack <- self.adminPackCollectionRef.withdraw(withdrawID: id)
                recipientPackCollectionRef.deposit(token: <- pack)
                log("Transfered the pack from the giver to the recipient")
            }

        }
    }
}