import SalesContract from 0xSalesContract

pub fun main(name: String): UInt64 {
    return SalesContract.getTotalSupplyForSKU(name: name)
}