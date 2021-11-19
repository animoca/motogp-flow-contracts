import SalesContract from 0xSalesContract

pub fun main(name: String): SalesContract.SKU {
    return SalesContract.getSKU(name: name);
}