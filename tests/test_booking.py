import pytest
import brownie

token_id = 119292438

@pytest.fixture
def booking_contract(Booking, FRMRegistry, Season, web3, accounts):
    farm_registry = FRMRegistry.deploy({'from': accounts[0]})
    season_contract = Season.deploy(farm_registry.address, {'from': accounts[0]})
    farm_registry.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Aphids', 'Fertilizer Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price)
    yield Booking.deploy(farm_registry.address, season_contract.address, {'from': accounts[0]})

def test_initial_state(booking_contract):

    # Assertions
    booking_contract.completedBookings() == 0

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

