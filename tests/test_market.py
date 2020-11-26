import pytest
import brownie

token_id = 4863475

@pytest.fixture
def market_contract(FRMRegistry, Season, Market, accounts, web3):
    farm_registry = FRMRegistry.deploy({'from': accounts[0]})
    farm_registry.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    season_contract = Season.deploy(farm_registry.address, {'from': accounts[0]})
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Infestor x32H', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    yield Market.deploy(farm_registry.address, season_contract.address, {'from': accounts[0]})

def test_initial_state(market_contract):

    # Assertions
    assert market_contract.platformTransactions() == 0
    assert market_contract.farmTransactions(token_id) == 0
    assert market_contract.totalMarkets() == 0

