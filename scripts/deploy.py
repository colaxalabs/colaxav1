from brownie import FRMRegistry, Season, accounts

def main():
    frmregistry_contract = FRMRegistry.deploy({'from': accounts[0]})
    Season.deploy(frmregistry_contract.address, {'from': accounts[0]})

