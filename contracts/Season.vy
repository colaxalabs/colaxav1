# @version ^0.2.0

# External Interfaces
interface Frmregistry:
    def exists(_tokenId: uint256) -> bool: view
    def updateState(_tokenId: uint256, _state: String[20]): nonpayable
    def getTokenState(_tokenId: uint256) -> String[20]: view

# Events

event OpenSeason:
  _tokenId: indexed(uint256)
  _season: indexed(String[20])

event ConfirmPreparations:
  _tokenId: indexed(uint256)
  _season: indexed(String[20])

event ConfirmPlanting:
  _tokenId: indexed(uint256)
  _season: indexed(String[20])

event Harvesting:
  _tokenId: indexed(uint256)
  _season: indexed(String[20])

# State data

# @dev Completed farm seasons
totalCompletedSeasons: uint256

# @dev Farm completed farm
farmCompleteSeason: HashMap[uint256, uint256]

# @dev Current farm season
runningSeason: HashMap[uint256, uint256]

# @dev Farm season data
struct SeasonData:
  tokenId: uint256
  crop: String[100]
  fertilizer: String[225]
  seedsUsed: String[225]
  seedsSupplier: String[225]
  expectedYield: String[50]
  harvestSupply: uint256
  harvestUnit: String[20]
  harvestPrice: String[225]

# @dev Map season data to farm
seasonData: HashMap[uint256, HashMap[uint256, SeasonData]]

# @dev Farm registry interface variable
farm_registry: Frmregistry

@external
def __init__(registry_contract_address: address):
  self.farm_registry = Frmregistry(registry_contract_address)

# @dev Return total completed seasons
# @return Completed seasons
@external
@view
def completeSeasons() -> uint256:
  return self.totalCompletedSeasons

# @dev Return current season for tokenized farm
# @param _tokenId Token ID
# @return uint256
@external
@view
def currentSeason(_tokenId: uint256) -> uint256:
  assert self.farm_registry.exists(_tokenId) == True
  return self.runningSeason[_tokenId]

# @dev Get token season
# @param _tokenId Token ID
# @return String
@external
@view
def getSeason(_tokenId: uint256) -> String[20]:
  assert self.farm_registry.exists(_tokenId) == True
  return self.farm_registry.getTokenState(_tokenId)

# @dev Query season data
# @param _tokenId Tokenized farm
# @param _index Season index
@external
@view
def querySeasonData(_tokenId: uint256, _index: uint256) -> SeasonData:
  assert self.farm_registry.exists(_tokenId) == True
  assert _index <= self.farmCompleteSeason[_tokenId]
  return (self.seasonData[_tokenId])[_index]

# @dev Farm complete season
# @param _tokenId Tokenized farm
@external
@view
def getFarmCompleteSeasons(_tokenId: uint256) -> uint256:
  assert self.farm_registry.exists(_tokenId) == True
  return self.farmCompleteSeason[_tokenId]

