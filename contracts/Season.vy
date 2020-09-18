# @version ^0.2.0

# External Interfaces
interface Frmregistry:
    def exists(_tokenId: uint256) -> bool: view
    def updateState(_tokenId: uint256, _state: String[20]): nonpayable
    def getTokenState(_tokneId: uint256) -> String[20]: view

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

