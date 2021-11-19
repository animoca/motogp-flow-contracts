import SalesContract from 0xSalesContract

pub fun main(address:Address): String {
    return SalesContract.convertAddressToString(address: address)
}