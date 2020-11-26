import pytest
import brownie

seasonDict = {
    'tokenId': 0,
    'openingDate': 1,
    'crop': 2,
    'preparationFertilizer': 3,
    'preparationFertilizerSupplier': 4,
    'seedsUsed': 5,
    'seedsSupplier': 6,
    'expectedYield': 7,
    'plantingFertilizer': 8,
    'plantingFertilizerSupplier': 9,
    'pestOrVirus': 10,
    'pesticideUsed': 11,
    'pesticideSupplier': 12,
    'harvestSupply': 13,
    'harvestUnit': 14,
    'harvestPrice': 15,
    'harvestDate': 16,
    'harvestImage': 17,
    'traceHash': 18,
    'bookers': 19
}

token_id = 4863475

@pytest.fixture
def season_contract(Season, FRMRegistry, accounts):
    frmregistry_contract = FRMRegistry.deploy({'from': accounts[0]})
    frmregistry_contract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    yield Season.deploy(frmregistry_contract.address, {'from': accounts[0]})

def test_initial_state(season_contract):

    # Assertions
    assert season_contract.currentSeason(token_id) == 0
    assert season_contract.completeSeasons() == 0
    assert season_contract.getSeason(token_id) == 'Dormant'

def test_get_tokenized_farm_current_season(season_contract):

    # Assertions
    assert season_contract.currentSeason(token_id) == 0

def test_get_current_season_for_invalid_tokenized_farm(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.currentSeason(3382)

def test_get_completed_seasons(season_contract):

    # Assertions
    assert season_contract.completeSeasons() == 0

def test_invalid_token_season(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.getSeason(4992)

def test_get_token_season(season_contract):

    # Assertions
    assert season_contract.getSeason(token_id) == 'Dormant'

def test_farm_season_opening(season_contract):
    season_contract.openSeason(token_id)

    # Assertions
    assert season_contract.currentSeason(token_id) == 1
    assert season_contract.getSeason(token_id) == 'Preparation'
    assert season_contract.farmStateCount('Preparation') == 1
    assert season_contract.farmStateCount('Dormant') == 0

def test_unrestricted_farm_season_opening(season_contract, accounts):

    # Error assertions
    with brownie.reverts('dev: only owner can update state'):
        season_contract.openSeason(token_id, {'from': accounts[1]})

def test_get_invalid_farm_season_data(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.querySeasonData(3892, 1)

def test_out_of_range_season_data_index(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.querySeasonData(token_id, 1)

def test_season_preparation(season_contract):

    season_contract.openSeason(token_id)

    # Assertions
    assert season_contract.currentSeason(token_id) == 1

    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure')

    total_complete_season = season_contract.currentSeason(token_id)
    season_data = list()
    for i in range(1, total_complete_season+1):
        season_data.append(season_contract.querySeasonData(token_id, i))

    # Assertions
    assert len(season_data) == 1
    assert season_data[0][seasonDict['crop']] == 'Tomatoe'
    assert season_data[0][seasonDict['preparationFertilizer']] == 'Organic Fertilizer'
    assert season_data[0][seasonDict['preparationFertilizerSupplier']] == 'Cow Shed Manure'
    assert season_contract.farmStateCount('Dormant') == 0
    assert season_contract.farmStateCount('Preparation') == 0
    assert season_contract.farmStateCount('Planting') == 1

def test_season_planting(season_contract):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')

    total_complete_season = season_contract.currentSeason(token_id)
    season_data = list()
    for i in range(1, total_complete_season+1):
        season_data.append(season_contract.querySeasonData(token_id, i))

    # Assertions
    assert len(season_data) == 1
    assert season_data[0][seasonDict['seedsUsed']] == 'F1'
    assert season_data[0][seasonDict['seedsSupplier']] == 'Kenya Seed Company'
    assert season_data[0][seasonDict['expectedYield']] == '1200kg'
    assert season_contract.farmStateCount('Dormant') == 0
    assert season_contract.farmStateCount('Preparation') == 0
    assert season_contract.farmStateCount('Planting') == 0
    assert season_contract.farmStateCount('Crop Growth') == 1
#
def test_season_crop_growth(season_contract):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Infestor x32H', 'Aphids Supplier')

    total_complete_season = season_contract.currentSeason(token_id)
    season_data = list()
    for i in range(1, total_complete_season+1):
        season_data.append(season_contract.querySeasonData(token_id, i))

    # Assertions
    assert len(season_data) == 1
    assert season_data[0][seasonDict['pestOrVirus']] == 'Army worm'
    assert season_data[0][seasonDict['pesticideUsed']] == 'Infestor x32H'
    assert season_data[0][seasonDict['pesticideSupplier']] == 'Aphids Supplier'
    assert season_contract.farmStateCount('Dormant') == 0
    assert season_contract.farmStateCount('Preparation') == 0
    assert season_contract.farmStateCount('Planting') == 0
    assert season_contract.farmStateCount('Crop Growth') == 0
    assert season_contract.farmStateCount('Harvesting') == 1
#
def test_season_harvesting(season_contract, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Infestor x32H', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')

    total_complete_season = season_contract.currentSeason(token_id)
    season_data = list()
    for i in range(1, total_complete_season+1):
        season_data.append(season_contract.querySeasonData(token_id, i))

    # Assertions
    assert season_contract.completeSeasons() == 1
    assert season_contract.getFarmCompleteSeasons(token_id) == 1
    assert len(season_data) == 1
    assert season_data[0][seasonDict['harvestSupply']] == 5
    assert season_data[0][seasonDict['harvestPrice']] == 1000000000000000000
    assert season_contract.resolvedHash(season_data[0][seasonDict['traceHash']]) == True
    assert season_contract.farmStateCount('Dormant') == 0
    assert season_contract.farmStateCount('Preparation') == 0
    assert season_contract.farmStateCount('Planting') == 0
    assert season_contract.farmStateCount('Crop Growth') == 0
    assert season_contract.farmStateCount('Harvesting') == 0
    assert season_contract.farmStateCount('Booking') == 1

def test_unrestricted_season_harvesting(season_contract):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    with brownie.reverts('dev: state is not crop growth'):
        season_contract.confirmGrowth(token_id, 'Army worm', 'Infestor x32H', 'Aphids Supplier')

# Booking
def test_unrestricted_owner_booking_his_her_harvest(season_contract, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    # Error assertions
    with brownie.reverts('dev: owner cannot book his/her harvest'):
        season_contract.bookHarvest(token_id, 14, 1)
#
def test_invalid_tokenized_farm_booking(season_contract, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    # Error assertions
    with brownie.reverts('dev: invalid token id'):
        season_contract.bookHarvest(3892, 15, 1)
#
def test_booking_unreasonable_amount(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    # Error assertions
    with brownie.reverts():
        season_contract.bookHarvest(token_id, 15, 1, {'from': accounts[1]})
#
def test_booking_with_zero_value(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    # Error assertions
    with brownie.reverts():
        season_contract.bookHarvest(token_id, 0, 10, {'from': accounts[1]})
#
def test_booking_with_invalid_season(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    # Error assertions
    with brownie.reverts():
        season_contract.bookHarvest(token_id, 3, 10, {'from': accounts[1]})
#
def test_booking_with_insufficient_fees(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    # Error assertions
    with brownie.reverts('dev: insufficient booking funds'):
        season_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1]})
#
def test_farm_harvest_booking(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    _price = web3.toWei(1, 'ether')
    season_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': _price * 3})

    total_complete_season = season_contract.currentSeason(token_id)
    season_data = list()
    for i in range(1, total_complete_season+1):
        season_data.append(season_contract.querySeasonData(token_id, i))

    # Assertions
    assert season_data[0][seasonDict['bookers']] == 1
    assert season_contract.totalFarmBookings(token_id) == 1
    assert season_contract.totalBookerBooking(accounts[1]) == 1
#
def test_get_all_booker_bookings(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    _price = web3.toWei(1, 'ether')
    season_contract.bookHarvest(token_id, 2, 1, {'from': accounts[1], 'value': _price * 2})
    season_contract.bookHarvest(token_id, 1, 1, {'from': accounts[1], 'value': _price * 1})

    booker_bookings = list()
    total_booker_bookings = season_contract.totalBookerBooking(accounts[1])
    for i in range(1, total_booker_bookings+1):
        _seasonBooked = season_contract.getSeasonBooked(i, accounts[1])
        booker_bookings.append(season_contract.getBookerBooking(_seasonBooked, accounts[1]))

    # Assertions
    assert len(booker_bookings) == 1
    assert booker_bookings[0][0] == 3
    assert booker_bookings[0][3] == accounts[1]
    expected_price = web3.toWei(3, 'ether')
    assert booker_bookings[0][4] == expected_price
    assert booker_bookings[0][5] == token_id
    assert booker_bookings[0][6] == 1
#
def test_get_all_farm_bookings(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    _price = web3.toWei(1, 'ether')
    season_contract.bookHarvest(token_id, 2, 1, {'from': accounts[1], 'value': _price * 2})
    season_contract.bookHarvest(token_id, 1, 1, {'from': accounts[1], 'value': _price * 1})
    season_contract.bookHarvest(token_id, 1, 1, {'from': accounts[1], 'value': _price * 1})

    total_farm_bookings = season_contract.totalFarmBookings(token_id)
    farm_bookings = list()
    for i in range(1, total_farm_bookings+1):
        farm_bookings.append(season_contract.getFarmBooking(token_id, i))

    assert len(farm_bookings) == 1

def test_season_closure(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    _price = web3.toWei(1, 'ether')
    season_contract.bookHarvest(token_id, 5, 1, {'from': accounts[1], 'value': _price * 5})
    season_contract.closeSeason(token_id, {'from': accounts[0]})

    # Assertions
    assert season_contract.getSeason(token_id) == 'Dormant'
    assert season_contract.farmStateCount('Dormant') == 1
    assert season_contract.farmStateCount('Preparation') == 0
    assert season_contract.farmStateCount('Planting') == 0
    assert season_contract.farmStateCount('Crop Growth') == 0
    assert season_contract.farmStateCount('Harvesting') == 0
    assert season_contract.farmStateCount('Booking') == 0

def test_unrestricted_season_closure(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    _price = web3.toWei(1, 'ether')
    season_contract.bookHarvest(token_id, 5, 1, {'from': accounts[1], 'value': _price * 5})

    # Error assertions
    with brownie.reverts('dev: only owner can close shop'):
        season_contract.closeSeason(token_id, {'from': accounts[1]})

# Receivership

def test_invalid_token_id_receivership(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    season_contract.bookHarvest(token_id, 5, 1, {'from': accounts[1], 'value': _price * 5})
    # Error assertions
    with brownie.reverts('dev: invalid token id'):
        season_contract.confirmReceivership(32393842, 2, 1, accounts[0], {'from': accounts[1]})
#
def test_zero_booker_volume_receivership(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    season_contract.bookHarvest(token_id, 5, 1, {'from': accounts[1], 'value': _price * 5})
    # Error assertions
    with brownie.reverts('dev: no bookings'):
        season_contract.confirmReceivership(token_id, 3, 1, accounts[0], {'from': accounts[3]})
#
def test_invalid_booker_volume_receivership(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    season_contract.bookHarvest(token_id, 5, 1, {'from': accounts[1], 'value': _price * 5})
    # Error assertions
    with brownie.reverts():
        season_contract.confirmReceivership(token_id, 6, 1, accounts[0], {'from': accounts[1]})
#
def test_confirm_harvest_booking_receivership(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    season_contract.bookHarvest(token_id, 5, 1, {'from': accounts[1], 'value': _price * 5})

    prev_farm_dues = accounts[0].balance()

    tx = season_contract.confirmReceivership(token_id, 1, 1, accounts[0], {'from': accounts[1]})

    current_farm_dues = accounts[0].balance()

    assert len(tx.events) == 1
    assert tx.events[0]['volume'] == 4
    assert tx.events[0]['deposit'] == web3.toWei(4, 'ether')
    assert season_contract.totalBookingDeliveredForBooker(accounts[1]) == 1
    assert season_contract.totalBookingDeliveredForFarm(token_id) == 1
    assert season_contract.totalReceivership() == 1
    assert prev_farm_dues != current_farm_dues

def test_tracing_initial_state(season_contract):
    season_contract.openSeason(token_id)

    # Assertions
    assert season_contract.allTraces() == 0
    assert season_contract.farmTraces(token_id) == 0

def test_tracing_invalid_tokenized_farm(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.farmTraces(32)

def test_invalid_season_hash(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.resolveSeasonHash('0xe91c254ad58860a02c788dfb5c1a65d6a8846ab1dc649631c7db16fef4af2dec')

def test_resolve_unresolved_invalid_hash(season_contract):

    # Assertions
    assert season_contract.resolvedHash('0xe91c254ad58860a02c788dfb5c1a65d6a8846ab1dc649631c7db16fef4af2dec') == False

def test_tracing_count_for_invalid_hash(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.tracesPerHash('0xe91c254ad58860a02c788dfb5c1a65d6a8846ab1dc649631c7db16fef4af2dec')

def test_traces_count_for_tokenized_farm(season_contract):

    # Assertions
    assert season_contract.farmTraces(token_id) == 0

def test_resolve_unhashed_season(season_contract):
    season_contract.openSeason(token_id)

    # Assertions
    assert season_contract.hashedSeason(token_id, season_contract.currentSeason(token_id)) == '0x0000000000000000000000000000000000000000000000000000000000000000'

def test_hash_season_data(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')

    # Assertions
    assert season_contract.resolvedHash(season_contract.hashedSeason(token_id, season_contract.currentSeason(token_id))) == True

def test_invalid_season_to_hash(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')

    # Error assertions
    with brownie.reverts():
        season_contract.hashedSeason(token_id, 22)

def test_invalid_token_id_for_season_hash(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')

    # Error assertions
    with brownie.reverts():
        season_contract.hashedSeason(32, 1)

def test_trace_season_hash(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')

    # Trace
    season_data = season_contract.resolveSeasonHash(season_contract.hashedSeason(token_id, season_contract.currentSeason(token_id)))

    # Assertions
    assert season_contract.tracesPerHash(season_contract.hashedSeason(token_id, season_contract.currentSeason(token_id))) == 1
    assert season_data.return_value['crop'] == 'Tomatoe'
    assert season_data.return_value['expectedYield'] == '1200kg'

