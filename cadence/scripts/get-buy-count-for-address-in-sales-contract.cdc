import SalesContract from 0xSalesContract

pub fun main(skuName: String, recipient: Address): UInt64 {
    return SalesContract.getBuyCountForAddress(skuName: skuName, recipient: recipient)
}