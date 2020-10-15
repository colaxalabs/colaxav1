import pytest
import brownie

token_id = 300012934

@pytest.fixture
def trace_contract(Trace, FRMRegistry, Season, accounts):
    frmregistry_contract = FRMRegistry.deploy({'from': accounts[0]})
    frmregistry_contract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    season_contract = Season.deploy(frmregistry_contract.address, {'from': accounts[0]})
    yield Trace.deploy(frmregistry_contract.address, season_contract.address, {'from': accounts[0]})

def test_initial_state(trace_contract):

    # Assertions
    assert trace_contract.allTraces() == 0

