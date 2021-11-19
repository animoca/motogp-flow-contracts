import SalesContract from 0xSalesContract
pub fun main(name: String): UFix64 {
    return SalesContract.getPriceForSKU(name: name)
}