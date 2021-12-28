import NFTStorefront from 0xNFTStorefront
import REVV from 0xREVV
pub fun main(): Bool {
    return NFTStorefront.isCommissionReceiverSet(typeIdentifier: Type<@REVV.Vault>().identifier)
}