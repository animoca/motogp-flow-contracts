# The SalesContract

## Summary
The SalesContract role is to enable on-chain sales of MotoGP packs.

Users buy directly from the buyPack method and get the pack deposited into their collection, if all conditions are met.
The admin manages sales by adding SKUs to the contract. A SKU is equivalent to a drop.

Each SKU has a list of serial numbers (equivalent to print numbers), and when the user buys a pack, a serial is selected from the SKUs serial list, and removed from the list. To make the serial selection hard to predict (pseuo-random) we employ a logic discussed further below for serial selection.

## Pack buy logic

### 1
On the MotoGP website, when the user clicks buy, the web app logic the calls the MotoGP backend signing service.

### 2
Using a private key, the backend signing service creates a signature which includes the user's address, a nonce unique to the address which is read from the SalesContract, and the pack type.
The signing service then sends the signature string back to user the user.

### 3
The user confirms a transaction, which includes the signature string, and the transaction calls to the SalesContract to buy pack.
The buyPack method takes the signature as one of its arguments, as well as payment related references and resources:

```
    pub fun buyPack(signature: String, // signature using backend private key, to be verified by contract's public key
                    nonce: UInt32, // account-specific counter, to protect against replay
                    packType: UInt64, // pack type + serial equal uniqueness
                    skuName: String, // which drop
                    recipient: Address, // account which will receive the pack 
                    paymentVaultRef: &FungibleToken.Vault, // the payment for the pack
                    recipientCollectionRef: &MotoGPPack.Collection{MotoGPPack.IPackCollectionPublic}) // the collection where the pack will be deposited
```

Inside the buyPack method, the signature is verifying using a public key which is a field on the contract, and that only the admin can set. 
The key is set on the contract, rather than the account, to ensure it is only used for this contract.

After the signature has been verified, the first byte is read from the signature and an index is created from it, which is used to select a serial from the serial list. That serial is then removed, and a pack is minted and deposited into the users collection. While not random, in the absence of onchain random number oracles on FLow, this appraoch makes it hard to predict what the next selected serial will be, while avoiding including the serial in the function's argument list (which could be changed by the user who submits the transaction).

The user's payment for packs comes from a Flow vault submitted in the buyPack transaction. The payment is deposited into a Flow vault at an address set on the SKU.

## How Run Tests

```
yarn test salesContract
```
