from brownie import FRMRegistry, Season, accounts

def main():
    acc = accounts.load('mkulima-acc1')
    frmregistry_contract = FRMRegistry.deploy({'from': acc})
    Season.deploy(frmregistry_contract.address, {'from': acc})

