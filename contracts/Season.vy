# @version ^0.2.0

# External Interfaces
interface Frmregistry:
    def ownerOf(_tokenId: uint256) -> address: view
    def exists(_tokenId: uint256) -> bool: view
    def transitionState(_tokenId: uint256, _state: String[20], _sender: address): nonpayable
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
  crop: String[225]
  preparationFertilizer: String[225]
  preparationFertilizerSupplier: String[225]
  seedsUsed: String[225]
  seedsSupplier: String[225]
  expectedYield: String[50]
  plantingFertilizer: String[225]
  plantingFertilizerSupplier: String[225]
  pesticideUsed: String[225]
  pesticideSupplier: String[225]
  harvestSupply: uint256
  harvestUnit: String[100]
  harvestPrice: uint256

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

# @dev Get season supply
# Throw if `_tokenId` is invalid
# Throw if `_seasonNo` > `currentSeason(_tokenId)`
# @param _tokenId Tokenized farm id
# @param _seasonNo Season number
@external
@view
def getSeasonSupply(_tokenId: uint256, _seasonNo: uint256) -> uint256:
  assert self.farm_registry.exists(_tokenId) == True
  assert _seasonNo <= self.runningSeason[_tokenId]
  return (self.seasonData[_tokenId])[_seasonNo].harvestSupply

# @dev Get token season
# @param _tokenId Token ID
# @return String
@external
@view
def getSeason(_tokenId: uint256) -> String[20]:
  assert self.farm_registry.exists(_tokenId) == True
  return self.farm_registry.getTokenState(_tokenId)

# @dev Open season: Token should be in dormant state to open new season
# @param _tokenId Tokenized farm ID
@external
def openSeason(_tokenId: uint256):
  assert self.farm_registry.getTokenState(_tokenId) == 'Dormant' # dev: is not dormant
  self.runningSeason[_tokenId] += 1
  self.farm_registry.transitionState(_tokenId, 'Preparation', msg.sender) # dev: only owner can update state

# @dev Confirm preparations for new plantings
# @param _tokenId Tokenized farm ID
# @param _crop Crop for new plantings
# @param _preparationFertilizer Fertilizer used during preparation
# @param _preparationFertilizerSupplier Supplier of the preparation fertilizer
@external
def confirmPreparations(_tokenId: uint256, _crop: String[225], _preparationFertilizer: String[225], _preparationFertilizerSupplier: String[225]):
  assert self.farm_registry.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm preparations
  assert self.farm_registry.getTokenState(_tokenId) == 'Preparation' # dev: state is not preparations
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].crop = _crop
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].preparationFertilizer = _preparationFertilizer
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].preparationFertilizerSupplier = _preparationFertilizerSupplier
  # Transition state
  self.farm_registry.transitionState(_tokenId, 'Planting', msg.sender)

# @dev Confirm planting
# @param _tokenId Tokenized farm ID
# @param _seedsUsed Seeds used during planting
# @param _seedsSupplier Seeds used supplier
# @param _expectedYield Seeds used expected yield
# @param _plantingFertilizer Fertilizer used during planting
# @param _plantingFertilizerSupplier Fertilizer supplier used during planting
@external
def confirmPlanting(_tokenId: uint256, _seedsUsed: String[225], _seedsSupplier: String[225], _expectedYield: String[50], _plantingFertilizer: String[225], _plantingFertilizerSupplier: String[225]):
  assert self.farm_registry.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm planting
  assert self.farm_registry.getTokenState(_tokenId) == 'Planting' # dev: state is not planting
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].seedsUsed = _seedsUsed
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].seedsSupplier = _seedsSupplier
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].expectedYield = _expectedYield
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].plantingFertilizer = _plantingFertilizer
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].plantingFertilizerSupplier = _plantingFertilizerSupplier
  # Transition state
  self.farm_registry.transitionState(_tokenId, 'Crop Growth', msg.sender)

# @dev Confirm crop growth
# @param _tokenId Tokenized farm ID
# @param _pesticideUsed Pesticide used
# @param _pesticideSupplier Pesticide supplier
@external
def confirmGrowth(_tokenId: uint256, _pesticideUsed: String[225], _pesticideSupplier: String[225]):
  assert self.farm_registry.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm crop growth
  assert self.farm_registry.getTokenState(_tokenId) == 'Crop Growth' # dev: state is not crop growth
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].pesticideUsed = _pesticideUsed
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].pesticideSupplier = _pesticideSupplier
  # Transition state
  self.farm_registry.transitionState(_tokenId, 'Harvesting', msg.sender)

# @dev Confirm harvesting
# @param _tokenId Tokenized farm ID
# @param _harvestSupply Total season harvest supply
# @param _harvestUnit Harvest supply unit
# @param _unitPrice Harvest price per unit
@external
def confirmHarvesting(_tokenId: uint256, _harvestSupply: uint256, _harvestUnit: String[100], _unitPrice: uint256):
  assert self.farm_registry.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm harvesting
  assert self.farm_registry.getTokenState(_tokenId) == 'Harvesting' # dev: state is not harvesting
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].harvestSupply = _harvestSupply
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].harvestUnit = _harvestUnit
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].harvestPrice = _unitPrice
  # Transition state
  self.farm_registry.transitionState(_tokenId, 'Booking', msg.sender)

# @dev Query season data
# @param _tokenId Tokenized farm
# @param _index Season index
@external
@view
def querySeasonData(_tokenId: uint256, _index: uint256) -> SeasonData:
  assert self.farm_registry.exists(_tokenId) == True
  assert _index <= self.runningSeason[_tokenId]
  return (self.seasonData[_tokenId])[_index]

# @dev Burn season supply
# @param _tokenId Tokenized farm ID
# @param _seasonNo Season number
# @param _volume Volume to burn
# Throw if `_seasonNo > currentSeason(_tokenId)`
# Throw if `_volume > (self.seasonData[_tokenId])[_seasonNo]`
@external
def burnSupply(_tokenId: uint256, _seasonNo: uint256, _volume: uint256):
  assert self.farm_registry.getTokenState(_tokenId) == 'Harvesting' # dev: not harvesting to burn supply
  assert _volume <= (self.seasonData[_tokenId])[_seasonNo].harvestSupply # dev: volume greater than available supply
  assert _seasonNo <= self.runningSeason[_tokenId] # dev: season number out of range
  assert self.farm_registry.exists(_tokenId) == True # dev: invalid token id
  (self.seasonData[_tokenId])[_seasonNo].harvestSupply -= _volume

# @dev Mint season supply
# @param _tokenId Tokenized farm ID
# @param _seasonNo Season number
# @param _volume Volume to burn
# Throw if `_seasonNo > currentSeason(_tokenId)`
# Throw if `_volume > (self.seasonSupply[_tokenId])[_seasonNo]`
@external
def mintSupply(_tokenId: uint256, _seasonNo: uint256, _volume: uint256):
  assert self.farm_registry.getTokenState(_tokenId) == 'Harvesting' # dev: not harvesting to mint supply
  assert self.farm_registry.exists(_tokenId) == True # dev: invalid token id
  assert _seasonNo <= self.runningSeason[_tokenId] # dev: season number out of range
  (self.seasonData[_tokenId])[_seasonNo].harvestSupply += _volume

# @dev Farm complete season
# @param _tokenId Tokenized farm
@external
@view
def getFarmCompleteSeasons(_tokenId: uint256) -> uint256:
  assert self.farm_registry.exists(_tokenId) == True
  return self.farmCompleteSeason[_tokenId]

# @dev Close season: token should be in harvesting state to close season
# @param _tokenId Tokenized farm ID
@external
def closeSeason(_tokenId: uint256):
  assert self.farm_registry.getTokenState(_tokenId) == 'Harvesting' # dev: is not harvesting
  assert (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].harvestSupply == 0 # dev: supply is not exhausted
  self.farmCompleteSeason[_tokenId] += 1
  self.totalCompletedSeasons += 1
  self.farm_registry.transitionState(_tokenId, 'Dormant', msg.sender)

