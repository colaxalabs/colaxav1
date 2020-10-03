import pytest
import brownie

token_id = 119292438

@pytest.fixture
def booking_contract(Booking, FRMRegistry, Season, web3, accounts):
    farmContract = FRMRegistry.deploy({'from': accounts[0]})
    seasonContract = Season.deploy(farmContract.address, {'from': accounts[0]})
    farmContract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    seasonContract.openSeason(token_id)
    seasonContract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    seasonContract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    seasonContract.confirmGrowth(token_id, 'Aphids', 'Fertilizer Supplier')
    _price = web3.toWei(1, 'ether')
    seasonContract.confirmHarvesting(token_id, 5, 'kg', _price)
    yield Booking.deploy(farmContract.address, seasonContract.address, {'from': accounts[0]})

def test_initial_state(booking_contract):

    # Assertions
    booking_contract.totalBooking() == 0

def test_unrestricted_owner_booking_his_her_harvest(booking_contract):

    # Error assertions
    with brownie.reverts('dev: owner cannot book his/her harvest'):
        booking_contract.bookHarvest(token_id, 14, 1)

def test_invalid_tokenized_farm_booking(booking_contract):

    # Error assertions
    with brownie.reverts('dev: invalid token id'):
        booking_contract.bookHarvest(3892, 15, 1)

def test_booking_unreasonable_amount(booking_contract, accounts):

    # Error assertions
    with brownie.reverts():
        booking_contract.bookHarvest(token_id, 15, 1, {'from': accounts[1]})

def test_booking_with_zero_value(booking_contract, accounts):

    # Error assertions
    with brownie.reverts():
        booking_contract.bookHarvest(token_id, 0, 10, {'from': accounts[1]})

def test_booking_with_invalid_season(booking_contract, accounts):

    # Error assertions
    with brownie.reverts():
        booking_contract.bookHarvest(token_id, 3, 10, {'from': accounts[1]})

def test_booking_with_insufficient_fees(booking_contract, accounts):

    # Error assertions
    with brownie.reverts('dev: insufficient booking funds'):
        booking_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1]})

def test_farm_harvest_booking(booking_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    booking_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': _price * 3})

    # Assertions
    assert booking_contract.totalFarmBookings(token_id) == 1
    assert booking_contract.totalBookerBooking(accounts[1]) == 1

def test_get_all_booker_bookings(booking_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    booking_contract.bookHarvest(token_id, 2, 1, {'from': accounts[1], 'value': _price * 2})
    booking_contract.bookHarvest(token_id, 1, 1, {'from': accounts[1], 'value': _price * 1})

    booker_bookings = list()
    total_booker_bookings = booking_contract.totalBookerBooking(accounts[1])
    for i in range(1, total_booker_bookings+1):
        _seasonBooked = booking_contract.getSeasonBooked(i, accounts[1])
        booker_bookings.append(booking_contract.getBookerBooking(_seasonBooked, accounts[1]))

    # Assertions
    assert len(booker_bookings) == 1
    assert booker_bookings[0][0] == 3
    assert booker_bookings[0][3] == accounts[1]
    expected_price = web3.toWei(3, 'ether')
    assert booker_bookings[0][4] == expected_price

def test_get_all_farm_bookings(booking_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    booking_contract.bookHarvest(token_id, 2, 1, {'from': accounts[1], 'value': _price * 2})
    booking_contract.bookHarvest(token_id, 1, 1, {'from': accounts[1], 'value': _price * 1})
    booking_contract.bookHarvest(token_id, 1, 1, {'from': accounts[1], 'value': _price * 1})

    total_farm_bookings = booking_contract.totalFarmBookings(token_id)
    farm_bookings = list()
    for i in range(1, total_farm_bookings+1):
        farm_bookings.append(booking_contract.getFarmBooking(token_id, i))

    assert len(farm_bookings) == 1

