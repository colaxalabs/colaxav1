import pytest
import brownie

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

def test_unrestricted_farm_season_opening(season_contract, accounts):

    # Error assertions
    with brownie.reverts('dev: only owner can transition farm state'):
        season_contract.openSeason(token_id, {'from': accounts[1]})

def test_unrestricted_season_closure(season_contract):

    # Error assertions
    with brownie.reverts('dev: is not harvesting'):
        season_contract.closeSeason(token_id)

def test_get_invalid_farm_season_data(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.querySeasonData(3892, 1)

def test_get_index_farm_season_data(season_contract):

    # Error assertions
    with brownie.reverts():
        season_contract.querySeasonData(token_id, 1)

def test_query_season_data(season_contract):

    # Assertions
    total_complete_season = season_contract.currentSeason(token_id)
    season_data = list()
    for i in range(1, total_complete_season+1):
        season_data.append(season_contract.querySeasonData(token_id, i))

    assert len(season_data) == 0

