import pytest

import brownie

token_id = 293730023

@pytest.fixture
def frmregistry_contract(FRMRegistry, accounts):
    yield FRMRegistry.deploy({'from': accounts[0]})

def tokenize_farm(frmregistry_contract, accounts):
    tx = frmregistry_contract.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    return tx

def test_initial_state(frmregistry_contract):

    # Assertions
    assert frmregistry_contract.totalSupply() == 0
    assert frmregistry_contract.exists(token_id) == False

def test_validate_tokenized_farm(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)

    # Assertions
    assert frmregistry_contract.exists(token_id) == True

def test_validate_invalid_tokenized_farm(frmregistry_contract):

    # Assertions
    assert frmregistry_contract.exists(2) == False

def test_get_nft_token_name(frmregistry_contract):

    # Assertions
    assert frmregistry_contract.name() == 'Mkulima'

def test_get_nft_token_symbol(frmregistry_contract):

    # Assertions
    assert frmregistry_contract.symbol() == 'MKL'

def test_tokenize_farm(frmregistry_contract, accounts):
    tx = tokenize_farm(frmregistry_contract, accounts)

    # Check log contents
    assert frmregistry_contract.exists(token_id) == True
    assert len(tx.events) == 2
    assert tx.events[1]['_owner'] == accounts[0]
    assert tx.events[1]['_tokenId'] == token_id
    assert tx.events[1]['_name'] == 'Arunga Vineyard'

def test_get_owner_of_tokenized_farm(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)

    # Assertions
    assert frmregistry_contract.ownerOf(token_id) == accounts[0]

def test_total_user_tokenized_farms(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)

    # Assertions
    assert frmregistry_contract.balanceOf(accounts[0]) == 1

def test_total_tokenized_farms(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)

    # Assertions
    assert frmregistry_contract.totalTokenizedFarms() == 1

def test_index_farms_belonging_to_an_account(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)
    user_total_farm = frmregistry_contract.balanceOf(accounts[0])
    user_farms = list()
    for i in range(1, user_total_farm+1):
        user_farms.append(frmregistry_contract.queryUserTokenizedFarm(i))

    assert user_total_farm == 1
    assert len(user_farms) == 1
    assert user_farms[0][0] == 'Arunga Vineyard'
    assert user_farms[0][6] == 'Dormant'

def test_index_all_tokenized_farms(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)
    total_indexed_farms = frmregistry_contract.totalTokenizedFarms()
    indexed_farms = list()
    for i in range(1, total_indexed_farms+1):
        indexed_farms.append(frmregistry_contract.queryTokenizedFarm(i))

    assert total_indexed_farms == 1
    assert len(indexed_farms) == 1
    assert indexed_farms[0][0] == 'Arunga Vineyard'
    assert indexed_farms[0][6] == 'Dormant'

def test_get_tokenized_farm_state(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)

    # Assertions
    assert frmregistry_contract.getTokenState(token_id) == 'Dormant'

def test_update_tokenized_farm_state(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)

    frmregistry_contract.transitionState(token_id, 'Preparation', accounts[0])

    # Assertions
    assert frmregistry_contract.getTokenState(token_id) == 'Preparation'

def test_unrestricted_tokenized_farm_state_update(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)

    # Error assertions
    with brownie.reverts():
        frmregistry_contract.transitionState(token_id, 'Preparation', accounts[1])

def test_update_invalid_tokenized_farm(frmregistry_contract, accounts):
    tokenize_farm(frmregistry_contract, accounts)

    # Error assertions
    with brownie.reverts():
        frmregistry_contract.transitionState(3, 'Planting', accounts[0])

