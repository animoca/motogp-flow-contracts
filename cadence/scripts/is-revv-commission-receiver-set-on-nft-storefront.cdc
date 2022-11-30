import MotoGPNFTStorefront from 0xMotoGPNFTStorefront
import REVV from 0xREVV
pub fun main(): Bool {
    return MotoGPNFTStorefront.isCommissionReceiverSet(typeIdentifier: Type<@REVV.Vault>().identifier)
}