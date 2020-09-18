import pytest
import brownie
from brownie import FRMRegistry

token_id = 4833475

@pytest.fixture
def season_contract(Season, accounts):
    frmregistry_contract = FRMRegistry.deploy({'from': accounts[0]})
    frmregistry_contract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    yield Season.deploy(frmregistry_contract.address, {'from': accounts[0]})

def test_initial_state(season_contract):
    # Assertions
    assert season_contract.currentSeason(token_id) == 0
    assert season_contract.completeSeasons() == 0

