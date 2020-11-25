# @version ^0.2.0

# External interfaces
interface Season:
  def currentSeason(_tokenId: uint256) -> uint256: view

interface Frmregistry:
  def exists(_tokenId: uint256) -> bool: view

# Events
event Trace:
  _tokenId: uint256
  _noOfTraces: uint256

# @dev Farm registry
farmContract: Frmregistry

# @dev Season contract
seasonContract: Season

# @dev Total number of complete traces
totalTraces: uint256

# @dev Tokenized farm complete traces
harvestTraces: HashMap[uint256, uint256]

# @dev Season traces completed for tokenized farm
seasonTraces: HashMap[uint256, HashMap[uint256, uint256]]

@external
def __init__(farm_contract_address: address, season_contract_address: address):
  self.farmContract = Frmregistry(farm_contract_address)
  self.seasonContract = Season(season_contract_address)

# @dev Get total traces
@external
@view
def allTraces() -> uint256:
  return self.totalTraces

# @dev Get completed farm traces
# @param _tokenId Tokenized farm id
# Throw if `farmContract.exists(_tokenId) == False`
@external
@view
def farmTraces(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True
  return self.harvestTraces[_tokenId]

# @dev Get completed season traces
# @param _seasonNo Season number
# Throw if `_seasonNo > seasonContract.currentSeason(_tokenId)`
@external
@view
def seasonTraces(_tokenId: uint256, _seasonNo: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True
  assert _seasonNo <= self.seasonContract.currentSeason(_tokenId)
  return (self.seasonTraces[_tokenId])[_seasonNo]

