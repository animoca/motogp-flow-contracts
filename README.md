# MotoGPNFTStorefront contract

This contract review request includes the MotoGPNFTStorefront contract and related transactions used in the storefront.test.js test suite.

The other contracts in the project are already deployed, and one development debug contract - please exclude those in the review.

# Summary
The MotoGPNFTStorefront contract is based on the NFTSTorefront contract by Dapper Labs: https://github.com/onflow/nft-storefront
The MotoGPNFTSTorefront contract in this repo has some changes vs the above reference. It includes a commission rate set at contract level, and removes the cuts from the createSaleoffer method. 

The reason for the changes is that we don't want the user to be able to determine the cuts when creating a SaleOffer transaction. For our marketplace, the cuts (= commissions) are determined by the contract, with a commission percentage going to MotoGP and the remainder to the NFT owner.
To keep the contract implementation as close to the original storefront contract as possible for easier audit and testing, we've kept the contract's internal use of cuts for calculation commissions.

We also added some fields to the SaleOffer events. These new fields will be used by our marketplace website (still in development).

# Contract
path: ./cadence/contracts/
* MotoGPNFTStorefront

# Related transactions
path: ./cadence/transactions/
* provision-nftstorefront
* set-commission-rate-on-nftstorefront
* list-pack-for-sale-for-revv-on-nftstorefront
* list-card-for-sale-for-revv-on-nftstorefront
* list-pack-for-sale-for-flow-on-nftstorefront
* list-card-for-sale-for-flow-on-nftstorefront
* buy-pack-from-nftstorefront-with-revv
* buy-card-from-nftstorefront-with-revv
* buy-card-from-nftstorefront-with-flow
* buy-pack-from-nftstorefront-with-flow
* buy-pack-from-nftstorefront-with-flow-and-remove-saleoffer
* clean-up-saleoffer-from-nftstorefront
* delist-from-nftstorefront
* remove-provisioned-nft-storefront

# Related scripts
path: ./cadence/scripts/
* get-saleoffer-ids-in-nftstorefront
* get-saleoffer-nftid-from-nftstorefront
* is-revv-commission-receiver-set-on-nft-storefront
* is-card-listed-on-storefront
* get-saleoffer-price-from-storefront
* get-card-ids-from-storefront
* get-pack-ids-from-nftstorefront

# Run Tests

```
yarn run storefront
```