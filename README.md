# NFTStorefront contract

This contract review request includes the NFTSTorefront contract and related transactions used in the storefront.test.js test suite.

The other contracts in the project are existing, already deployed contracts and one development debug contract - please exclude those in the review.

# Summary
The NFTStorefront contract is based on the contract with same name developed by Dapper Lab: https://github.com/onflow/nft-storefront
The NFTSTorefront contract in this repo has some changes vs the above references. Notably, it includes a commission rate set at contract level, and removes the cuts from the create-saleoffer method.

The reason for the changes is that we don't want the user to be able to determine the cuts when creating a SaleOffer transaction. For our marketplace, the cuts (= commissions) are determined by the contract.
To keep the implementation as close to the original storefront contract for easier audit, we'v kep the contract's internal use of cuts for calculation commissions.

# Contract:
[+] NFTSTorefront

# Related transactions:
[+] provision-nftstorefront
[+] set-commission-rate-on-nftstorefront
[+] list-pack-for-sale-for-revv-on-nftstorefront
[+] list-card-for-sale-for-revv-on-nftstorefront
[+] list-pack-for-sale-for-flow-on-nftstorefront
[+] list-card-for-sale-for-flow-on-nftstorefront
[+] buy-pack-from-nftstorefront-with-revv
[+] buy-card-from-nftstorefront-with-revv
[+] buy-card-from-nftstorefront-with-flow
[+] buy-pack-from-nftstorefront-with-flow
[+] buy-pack-from-nftstorefront-with-flow-and-remove-saleoffer
[+] clean-up-saleoffer-from-nftstorefront
[+] delist-from-nftstorefront
[+] remove-provisioned-nft-storefront

# Related scripts
[+] get-saleoffer-ids-in-nftstorefront
[+] get-saleoffer-nftid-from-nftstorefront
[+] is-revv-commission-receiver-set-on-nft-storefront
[+] is-card-listed-on-storefront
[+] get-saleoffer-price-from-storefront
[+] get-card-ids-from-storefront
[+] get-pack-ids-from-nftstorefront
