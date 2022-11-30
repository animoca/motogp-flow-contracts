import PackOpener from 0xPackOpener
import MotoGPCard from 0xMotoGPCard
import MotoGPPack from 0xMotoGPPack

transaction {

  prepare(acct: AuthAccount) {

    let packCollectionRef = acct.borrow<&MotoGPPack.Collection>(from: /storage/motogpPackCollection)
    ?? panic("Could not borrow AuthAccount's Pack collection")

    if acct.borrow<&PackOpener.Collection>(from: /storage/motogpPackOpenerCollection) == nil {
        let cardCollectionCap: Capability<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}> = acct.getCapability<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}>(/public/motogpCardCollection)
        let packOpenerCollection <- PackOpener.createEmptyCollection(cardCollectionCap: cardCollectionCap)
        acct.save(<- packOpenerCollection, to: PackOpener.packOpenerStoragePath)
        acct.link<&PackOpener.Collection{PackOpener.IPackOpenerPublic}>(PackOpener.packOpenerPublicPath, target: PackOpener.packOpenerStoragePath) 
    }
  }

  execute {}
}