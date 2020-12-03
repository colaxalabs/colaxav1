from brownie import FRMRegistry, Market, Season, accounts

def main():
    acc = accounts.load('mkulima-acc1')
    frmregistry_contract = FRMRegistry.deploy({'from': acc})
    season_contract = Season.deploy(frmregistry_contract.address, {'from': acc})
    Market.deploy(frmregistry_contract.address, season_contract.address,{'from': acc})

