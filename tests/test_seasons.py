import pytest
import brownie

seasonDict = {
    'tokenId': 0,
    'openingDate': 1,
    'crop': 2,
    'preparationFertilizer': 3,
    'preparationFertilizerSupplier': 4,
    'preparationDate': 5,
    'seedsUsed': 6,
    'seedsSupplier': 7,
    'expectedYield': 8,
    'plantingFertilizer': 9,
    'plantingFertilizerSupplier': 10,
    'plantingDate': 11,
    'pestOrVirus': 12,
    'pesticideUsed': 13,
    'pesticideSupplier': 14,
    'date': 15,
    'harvestDate': 16,
    'traceHash': 17
}

token_id = 4863475

@pytest.fixture
def season_contract(Season, FRMRegistry, accounts):
    frmregistry_contract = FRMRegistry.deploy({'from': accounts[0]})
    frmregistry_contract.tokenizeLand('Arunga Vineyard', '294.32ha', 'Lyaduywa, Kenya', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
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
    assert season_contract.resolvedHash(season_data[0][seasonDict['traceHash']]) == True

def test_unrestricted_season_harvesting(season_contract):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    with brownie.reverts('dev: state is not crop growth'):
        season_contract.confirmGrowth(token_id, 'Army worm', 'Infestor x32H', 'Aphids Supplier')

def test_season_closure(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    _price = web3.toWei(1, 'ether')
    season_contract.closeSeason(token_id, {'from': accounts[0]})

    # Assertions
    assert season_contract.getSeason(token_id) == 'Dormant'

def test_unrestricted_season_closure(season_contract, accounts, web3):
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Aphids', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    _price = web3.toWei(1, 'ether')

    # Error assertions
    with brownie.reverts('dev: only owner can close shop'):
        season_contract.closeSeason(token_id, {'from': accounts[1]})

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
    season_contract.resolvedHash('0xe91c254ad58860a02c788dfb5c1a65d6a8846ab1dc649631c7db16fef4af2dec') == False

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
    with brownie.reverts('dev: invalid season'):
        season_contract.hashedSeason(token_id, season_contract.currentSeason(token_id))

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

