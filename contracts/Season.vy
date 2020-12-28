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

# @dev Total farm state count
totalFarmState: HashMap[String[100], uint256]

# @dev Completed farm seasons
totalCompletedSeasons: uint256

# @dev Farm completed farm
farmCompleteSeason: HashMap[uint256, uint256]

# @dev Current farm season
runningSeason: HashMap[uint256, uint256]

# @dev Farm season data
struct SeasonData:
  # Open season
  tokenId: uint256
  openingDate: uint256
  # Confirm preparations
  crop: String[225]
  preparationFertilizer: String[225]
  preparationFertilizerSupplier: String[225]
  preparationFertilizerProof: String[225]
  preparationDate: uint256
  # Confirm planting
  seedsUsed: String[225]
  seedsSupplier: String[225]
  seedProof: String[225]
  expectedYield: String[50]
  plantingFertilizer: String[225]
  plantingFertilizerSupplier: String[225]
  plantingFertilizerProof: String[225]
  plantingDate: uint256
  # Confirm crop growth
  pestOrVirus: String[225]
  pesticideUsed: String[225]
  pesticideImage: String[225]
  pesticideSupplier: String[225]
  proofOfTxForPesticide: String[225]
  growthDate: uint256
  # Confirm harvesting
  harvestDate: uint256
  harvestSupply: String[225]
  traceHash: bytes32

# @dev Map season data to farm
seasonData: HashMap[uint256, HashMap[uint256, SeasonData]]

# @dev Farm registry interface variable
farmContract: Frmregistry

# @dev All traces
totalTraces: uint256

# @dev Resolved hashes
resolvedHashes: HashMap[bytes32, bool]

# @dev Map tokenized farm season to its hash
seasonHash: HashMap[uint256, HashMap[uint256, bytes32]]

# @dev Season data hashing
seasonDataHash: HashMap[bytes32, SeasonData]

# @dev Season data hash traces
hashTraces: HashMap[bytes32, uint256]

# @dev Tokenized farm traces
harvestTraces: HashMap[uint256, uint256]

@external
def __init__(registry_contract_address: address):
  self.farmContract = Frmregistry(registry_contract_address)

# @dev Get token season
# @param _tokenId Token ID
# @return String
@external
@view
def getSeason(_tokenId: uint256) -> String[20]:
  assert self.farmContract.exists(_tokenId) == True
  return self.farmContract.getTokenState(_tokenId)

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
  assert self.farmContract.exists(_tokenId) == True
  return self.runningSeason[_tokenId]

# @dev Open season: Token should be in dormant state to open new season
# @param _tokenId Tokenized farm ID
@external
def openSeason(_tokenId: uint256):
  assert self.farmContract.getTokenState(_tokenId) == 'Dormant' # dev: is not dormant
  self.runningSeason[_tokenId] += 1
  _runningSeason: uint256 = self.runningSeason[_tokenId]
  (self.seasonData[_tokenId])[_runningSeason].tokenId = _tokenId
  (self.seasonData[_tokenId])[_runningSeason].openingDate = block.timestamp
  self.farmContract.transitionState(_tokenId, 'Preparation', msg.sender) # dev: only owner can update state

# @dev Confirm preparations for new plantings
# @param _tokenId Tokenized farm ID
# @param _crop Crop for new plantings
# @param _preparationFertilizer Fertilizer used during preparation
# @param _preparationFertilizerSupplier Supplier of the preparation fertilizer
# @param _txBinding Proof of Tx btwn farmer and supplier
@external
def confirmPreparations(
    _tokenId: uint256,
    _crop: String[225],
    _preparationFertilizer: String[225],
    _preparationFertilizerSupplier: String[225],
    _txBinding: String[225]
  ):
    assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm preparations
    assert self.farmContract.getTokenState(_tokenId) == 'Preparation' # dev: state is not preparations
    _runningSeason: uint256 = self.runningSeason[_tokenId]
    (self.seasonData[_tokenId])[_runningSeason].crop = _crop
    (self.seasonData[_tokenId])[_runningSeason].preparationFertilizer = _preparationFertilizer
    (self.seasonData[_tokenId])[_runningSeason].preparationFertilizerSupplier = _preparationFertilizerSupplier
    (self.seasonData[_tokenId])[_runningSeason].preparationFertilizerProof = _txBinding
    (self.seasonData[_tokenId])[_runningSeason].preparationDate = block.timestamp
    # Transition state
    self.farmContract.transitionState(_tokenId, 'Planting', msg.sender)

# @dev Confirm planting
# @param _tokenId Tokenized farm ID
# @param _seedsUsed Seeds used during planting
# @param _seedsSupplier Seeds used supplier
# @param _expectedYield Seeds used expected yield
# @param _plantingFertilizer Fertilizer used during planting
# @param _plantingFertilizerSupplier Fertilizer supplier used during planting
# @param _seedProof Proof binding btwn farmer and seeds supplier
# @param _plantingFertilizerProof Proof binding btwn farmer and planting fertilizer supplier
@external
def confirmPlanting(
    _tokenId: uint256,
    _seedsUsed: String[225],
    _seedsSupplier: String[225],
    _seedProof: String[225],
    _expectedYield: String[50],
    _plantingFertilizer: String[225],
    _plantingFertilizerSupplier: String[225],
    _plantingFertilizerSupplierProof: String[225]
  ):
    assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm planting
    assert self.farmContract.getTokenState(_tokenId) == 'Planting' # dev: state is not planting
    _runningSeason: uint256 = self.runningSeason[_tokenId]
    (self.seasonData[_tokenId])[_runningSeason].seedsUsed = _seedsUsed
    (self.seasonData[_tokenId])[_runningSeason].seedsSupplier = _seedsSupplier
    (self.seasonData[_tokenId])[_runningSeason].seedProof = _seedProof
    (self.seasonData[_tokenId])[_runningSeason].expectedYield = _expectedYield
    (self.seasonData[_tokenId])[_runningSeason].plantingFertilizer = _plantingFertilizer
    (self.seasonData[_tokenId])[_runningSeason].plantingFertilizerSupplier = _plantingFertilizerSupplier
    (self.seasonData[_tokenId])[_runningSeason].plantingFertilizerProof = _plantingFertilizerSupplierProof
    (self.seasonData[_tokenId])[_runningSeason].plantingDate = block.timestamp
    # Transition state
    self.farmContract.transitionState(_tokenId, 'Crop Growth', msg.sender)

# @dev Confirm crop growth
# @param _tokenId Tokenized farm ID
# @param _pesticideUsed Pesticide used
# @param _pesticideSupplier Pesticide supplier
# @param _image Image of the disease of weed
# @param _proofOfTxForPesticide Proof binding btwn farmer and pesticide supplier
@external
def confirmGrowth(
    _tokenId: uint256,
    _pestOrVirus: String[225],
    _image: String[225],
    _pesticideUsed: String[225],
    _pesticideSupplier: String[225],
    _proofOfTxForPesticide: String[225]
  ):
    assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm crop growth
    assert self.farmContract.getTokenState(_tokenId) == 'Crop Growth' # dev: state is not crop growth
    _runningSeason: uint256 = self.runningSeason[_tokenId]
    (self.seasonData[_tokenId])[_runningSeason].pestOrVirus = _pestOrVirus
    (self.seasonData[_tokenId])[_runningSeason].pesticideImage = _image
    (self.seasonData[_tokenId])[_runningSeason].pesticideUsed = _pesticideUsed
    (self.seasonData[_tokenId])[_runningSeason].pesticideSupplier = _pesticideSupplier
    (self.seasonData[_tokenId])[_runningSeason].proofOfTxForPesticide = _proofOfTxForPesticide
    (self.seasonData[_tokenId])[_runningSeason].growthDate = block.timestamp
    # Transition state
    self.farmContract.transitionState(_tokenId, 'Harvesting', msg.sender)

# @dev Confirm harvesting
# @param _tokenId Tokenized farm ID
# @param _harvestSupply Total season harvest supply
# @param _harvestUnit Harvest supply unit
# @param _unitPrice Harvest price per unit
@external
def confirmHarvesting(_tokenId: uint256, _supply: String[225]):
  assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm harvesting
  assert self.farmContract.getTokenState(_tokenId) == 'Harvesting' # dev: state is not harvesting
  _runningSeason: uint256 = self.runningSeason[_tokenId]
  # When was the harvest date
  (self.seasonData[_tokenId])[_runningSeason].harvestDate = block.timestamp
  (self.seasonData[_tokenId])[_runningSeason].harvestSupply = _supply
  # Hash season data after harvest confirmation
  _tr: uint256 = _tokenId + _runningSeason
  _trHash: bytes32 = convert(_tr, bytes32)
  _hash: bytes32 = keccak256(_trHash)
  (self.seasonData[_tokenId])[_runningSeason].traceHash = _hash # Trace ID
  # Resolve season hash to season data
  self.seasonDataHash[_hash] = (self.seasonData[_tokenId])[_runningSeason]
  self.resolvedHashes[_hash] = True
  # Resolve hash to farm season
  (self.seasonHash[_tokenId])[_runningSeason] = _hash
  # Transition state
  self.farmContract.transitionState(_tokenId, 'Marketing', msg.sender)
  self.farmCompleteSeason[_tokenId] += 1
  self.totalCompletedSeasons += 1

# @dev Query season data
# @param _tokenId Tokenized farm
# @param _index Season index
@external
@view
def querySeasonData(_tokenId: uint256, _index: uint256) -> SeasonData:
  assert self.farmContract.exists(_tokenId) == True
  assert _index <= self.runningSeason[_tokenId]
  return (self.seasonData[_tokenId])[_index]

# @dev Farm complete season
# @param _tokenId Tokenized farm
@external
@view
def getFarmCompleteSeasons(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True
  return self.farmCompleteSeason[_tokenId]

# @dev Close season: token should be in harvesting state to close season
# @param _tokenId Tokenized farm ID
@external
def closeSeason(_tokenId: uint256):
  assert self.farmContract.exists(_tokenId) == True
  assert self.farmContract.getTokenState(_tokenId) == 'Marketing' # dev: is not harvesting
  # Is market supply exhausted?
  assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can close shop
  self.farmContract.transitionState(_tokenId, 'Dormant', msg.sender)

# @dev Get traces
# @return uint256
@external
@view
def allTraces() -> uint256:
  return self.totalTraces

# @dev Get farm traces
# @param _tokenId Tokenized farm id
# @return uint256
@external
@view
def farmTraces(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True
  return self.harvestTraces[_tokenId]

# @dev Season data hash status
# @param _hash Season data hash
@external
@view
def resolvedHash(_hash: bytes32) -> bool:
  assert _hash != EMPTY_BYTES32
  return self.resolvedHashes[_hash]

# @dev Resolve season data hash
# @param _hash Season data hash signature
# @return SeasonData
# Throw if `self.resolvedHashes[_hash] == False`
@external
def resolveSeasonHash(_hash: bytes32) -> SeasonData:
  assert _hash != EMPTY_BYTES32
  assert self.resolvedHashes[_hash] == True
  # Count traces per hash
  self.hashTraces[_hash] += 1
  # Count total performed trace
  self.totalTraces += 1
  return self.seasonDataHash[_hash]

# @dev Total tracing per hash
# @param _hash Season data hash
# @return uint256
# Throw if `self.resolvedHashes[_hash] == False`
@external
@view
def tracesPerHash(_hash: bytes32) -> uint256:
  assert _hash != EMPTY_BYTES32
  assert self.resolvedHashes[_hash] == True
  return self.hashTraces[_hash]

# @dev Get farm season data hash
# @param _tokenId Tokenized farm id
# @param _seasonNo Season number
# @return bytes32
# Throw if `farmContract.exists(_tokenId) == False`
# Throw if `_seasonNo > self.runningSeason[_tokenId]`
@external
@view
def hashedSeason(_tokenId: uint256, _seasonNo: uint256) -> bytes32:
  assert self.farmContract.exists(_tokenId) == True
  assert _seasonNo <= self.runningSeason[_tokenId]
  assert (self.seasonHash[_tokenId])[_seasonNo] != EMPTY_BYTES32 # dev: invalid season
  return (self.seasonHash[_tokenId])[_seasonNo]

