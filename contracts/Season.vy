# @version ^0.2.0

# External Interfaces
interface Frmregistry:
    def name() -> String[4]: view
    def symbol() -> String[3]: view

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
currentSeason: HashMap[uint256, uint256]

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
def __init__(contract_address: address):
  self.farm_registry = Frmregistry(contract_address)

# @dev Return total completed seasons
@external
@view
def completeSeasons() -> uint256:
  return self.totalCompletedSeasons

