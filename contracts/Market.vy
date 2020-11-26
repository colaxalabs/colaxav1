# @version ^0.2.0

# External Interfaces
interface Frmregistry:
  def ownerOf(_tokenId: uint256) -> address: view
  def exists(_tokenId: uint256) -> bool: view
  def getTokenState(_tokenId: uint256) -> String[10]: view

# Events

# @dev Sealed platform tx
platformTx: uint256

# @dev Sealed user tx
accountTx: HashMap[address, uint256]

# @dev Sealed farm tx
farmTx: HashMap[uint256, uint256]

# @dev Registry contract
farmContract: Frmregistry

# @dev Total number of markets
markets: uint256

# @dev Defaults
@external
def __init__(registry_contract_address: address):
  self.farmContract = Frmregistry(registry_contract_address)

# @dev Get total deal sealed on the platform
@external
@view
def platformTransactions() -> uint256:
  return self.platformTx

# @dev Get total deal sealed for an account/user
# Throw if `_address != ZERO_ADDRESS`
@external
@view
def userTransactions(_address: address) -> uint256:
  assert _address != ZERO_ADDRESS
  return self.accountTx[_address]

# @dev Get total deal sealed for a farm
# Throw if `farmContract.exists(_tokenId) == False`
@external
@view
def farmTransactions(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True
  return self.farmTx[_tokenId]

