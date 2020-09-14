import pytest

@pytest.fixture
def frmregistry_contract(FRMRegistry, accounts):
    yield FRMRegistry.deploy({'from': accounts[0]})

def test_initial_state(frmregistry_contract):
    assert frmregistry_contract.totalSupply() == 0

def test_tokenize_farm(frmregistry_contract, accounts):
    tx = frmregistry_contract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', 48983476, {'from': accounts[0]})

    # Check log contents
    assert len(tx.events) == 2
    assert tx.events[1]['_owner'] == accounts[0]
    assert tx.events[1]['_tokenId'] == 48983476
    assert tx.events[1]['_name'] == 'Arunga Vineyard'

def test_total_user_tokenized_farms(frmregistry_contract, accounts):
    frmregistry_contract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', 48983476, {'from': accounts[0]})

    # Assertions
    assert frmregistry_contract.balanceOf(accounts[0]) == 1

def test_total_tokenized_farms(frmregistry_contract, accounts):
    frmregistry_contract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', 48983476, {'from': accounts[0]})

    # Assertions
    assert frmregistry_contract.totalTokenizedFarms() == 1

