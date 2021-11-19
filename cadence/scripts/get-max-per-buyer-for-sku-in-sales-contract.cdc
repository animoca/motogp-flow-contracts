import SalesContract from 0xSalesContract

pub fun main(skuName: String): UInt64 {
    return SalesContract.getMaxPerBuyerForSKU(name: skuName)
}