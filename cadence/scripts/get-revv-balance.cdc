import FungibleToken from 0xFungibleToken
import REVV from 0xREVV

pub fun main(address: Address): UFix64 {
    let account = getAccount(address)

    let vaultRef = account.getCapability(REVV.RevvBalancePublicPath)!
        .borrow<&REVV.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}