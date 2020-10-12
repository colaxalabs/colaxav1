import pytest
import brownie

token_id = 9238934120

@pytest.fixture
def receivership_contract(Booking, FRMRegistry, Receivership, Season, accounts, web3):
    farmContract = FRMRegistry.deploy({'from': accounts[0]})
    seasonContract = Season.deploy(farmContract.address, {'from': accounts[0]})
    bookingContract = Booking.deploy(farmContract.address, seasonContract.address, {'from': accounts[0]})
    farmContract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    seasonContract.openSeason(token_id)
    seasonContract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    seasonContract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    seasonContract.confirmGrowth(token_id, 'Aphids', 'Fertilizer Supplier')
    _price = web3.toWei(1, 'ether')
    seasonContract.confirmHarvesting(token_id, 5, 'kg', _price)
    bookingContract.bookHarvest(token_id, 5, 1, {'from': accounts[1], 'value': _price * 5})
    yield Receivership.deploy(bookingContract.address, farmContract.address, {'from': accounts[0]})
def test_initial_state(receivership_contract, accounts):

    # Assertions
    assert receivership_contract.totalBookingDeliveredForBooker(accounts[1]) == 0
    assert receivership_contract.totalBookingDeliveredForFarm(token_id) == 0

def test_invalid_token_id_receivership(receivership_contract, accounts):

    # Error assertions
    with brownie.reverts('dev: invalid token id'):
        receivership_contract.confirmReceivership(32393842, 2, 1, accounts[2], accounts[0], {'from': accounts[1]})

def test_zero_booker_volume_receivership(receivership_contract, accounts):

    # Error assertions
    with brownie.reverts('dev: no bookings'):
        receivership_contract.confirmReceivership(token_id, 3, 1, accounts[2], accounts[0], {'from': accounts[3]})

def test_invalid_booker_volume_receivership(receivership_contract, accounts):

    # Error assertions
    with brownie.reverts():
        receivership_contract.confirmReceivership(token_id, 6, 1, accounts[2], accounts[0], {'from': accounts[1]})

def test_confirm_harvest_booking_receivership(receivership_contract, accounts, web3):
    prev_beneficiary_balance = accounts[2].balance()
    prev_farm_dues = accounts[0].balance()

    tx = receivership_contract.confirmReceivership(token_id, 1, 1, accounts[2], accounts[0], {'from': accounts[1]})

    current_beneficiary_balance = accounts[2].balance()
    current_farm_dues = accounts[0].balance()

    assert len(tx.events) == 1
    assert tx.events[0]['volume'] == 4
    assert tx.events[0]['deposit'] == web3.toWei(4, 'ether')
    assert receivership_contract.totalBookingDeliveredForBooker(accounts[1]) == 1
    assert receivership_contract.totalBookingDeliveredForFarm(token_id) == 1
    assert receivership_contract.totalReceivership() == 1
    assert prev_beneficiary_balance != current_beneficiary_balance
    assert prev_farm_dues != current_farm_dues

