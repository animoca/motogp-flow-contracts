import SalesContract from 0xSalesContract

pub fun main(address: Address): UInt64 {
    return SalesContract.getNonce(address: address);
}