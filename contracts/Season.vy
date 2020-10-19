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

event Receivership:
  volume: uint256
  deposit: uint256

# State data

# @dev Completed farm seasons
totalCompletedSeasons: uint256

# @dev Total completed delivery
completedDelivery: uint256

# @dev Delivered bookings for booker
bookerDelivery: HashMap[address, uint256]

# @dev Delivered bookings for tokenized farm
tokenizedFarmDelivery: HashMap[uint256, uint256]

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
  traceHash: bytes32

# @dev Map season data to farm
seasonData: HashMap[uint256, HashMap[uint256, SeasonData]]

# @dev Farm registry interface variable
farmContract: Frmregistry

# Booking type
struct BookingType:
  volume: uint256
  delivered: bool
  cancelled: bool
  booker: address
  deposit: uint256

# @dev Total completed bookings
totalBookings: uint256

# @dev Index all bookings to tokenized farm
totalFarmBooking: HashMap[uint256, uint256] # token => total number of farm bookings
farmBookings: HashMap[uint256, HashMap[uint256, BookingType]] # token => totalFarmBooking[token]: index => Booking{}

# @dev Index all bookings to address
totalBookerBookings: HashMap[address, uint256] # address => total number of booker bookings
bookerBookings: HashMap[address, HashMap[uint256, BookingType]] # address => seasonNo[_tokenId]: index => Booking{}
seasonsBooked: HashMap[address, HashMap[uint256, uint256]] # seasons booked indexed by totalBookerBookings

# @dev Season bookings(for analytics)
seasonalBookings: HashMap[uint256, uint256] # season => number of season bookings

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

# @dev Get total completed delivery/receivership
# @return uint256
@external
@view
def totalReceivership() -> uint256:
  return self.completedDelivery

# @dev Get booker total delivery
# @param _address Booker address
# Throw if `_address == ZERO_ADDRESS`
@external
@view
def totalBookingDeliveredForBooker(_address: address) -> uint256:
  assert _address != ZERO_ADDRESS
  return self.bookerDelivery[_address]

# @dev Get farm total delivery
# @param _tokenId Tokenized farm ID
# Throw if `_tokenId == False`
@external
@view
def totalBookingDeliveredForFarm(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  return self.tokenizedFarmDelivery[_tokenId]

# @dev Return total completed bookings
@external
@view
def totalBooking() -> uint256:
  return self.totalBookings

# @dev Return farm total bookings
# @param _tokenId Tokenized farm ID
@external
@view
def totalFarmBookings(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  return self.totalFarmBooking[_tokenId]

# @dev Get total booker bookings
# @param _address Booker address
@external
@view
def totalBookerBooking(_address: address) -> uint256:
  assert _address != ZERO_ADDRESS # dev: invalid address
  return self.totalBookerBookings[_address]

# @dev Get token season
# @param _tokenId Token ID
# @return String
@external
@view
def getSeason(_tokenId: uint256) -> String[20]:
  assert self.farmContract.exists(_tokenId) == True
  return self.farmContract.getTokenState(_tokenId)

# @dev Get seasons booked
# @param _index Index
# Throw if `_index > self.totalBookerBookings[msg.sender]`
# @return uint256
@external
@view
def getSeasonBooked(_index: uint256, _sender: address) -> uint256:
  assert _index <= self.totalBookerBookings[_sender] # dev: out of range
  return (self.seasonsBooked[_sender])[_index]

# @dev Get booker booking
# @param _index Index
# @param _booker Booker address
@external
@view
def getBookerBooking(_seasonIndex: uint256, _booker: address) -> BookingType:
  assert _booker != ZERO_ADDRESS
  return (self.bookerBookings[_booker])[_seasonIndex]

# @dev Get booker deposit
# @param _booker Booker address
# @param _seasonNo Season number
@external
@view
def bookerDeposit(_booker: address, _seasonNo: uint256) -> uint256:
  assert _booker != ZERO_ADDRESS
  return (self.bookerBookings[_booker])[_seasonNo].deposit

# @dev Get booker volume
# @param _booker Booker address
# @param _seasonNo Season number
@external
@view
def bookerVolume(_booker: address, _seasonNo: uint256) -> uint256:
  assert _booker != ZERO_ADDRESS
  return (self.bookerBookings[_booker])[_seasonNo].volume

# @dev Query farm booking
# @param _tokenId Tokenized farm ID
# @param _index Index
@external
@view
def getFarmBooking(_tokenId: uint256, _index: uint256) -> BookingType:
  assert self.farmContract.exists(_tokenId) == True
  assert _index <= self.totalFarmBooking[_tokenId]
  return (self.farmBookings[_tokenId])[_index]

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

# @dev Get season supply
# Throw if `_tokenId` is invalid
# Throw if `_seasonNo` > `currentSeason(_tokenId)`
# @param _tokenId Tokenized farm id
# @param _seasonNo Season number
@external
@view
def getSeasonSupply(_tokenId: uint256, _seasonNo: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True
  assert _seasonNo <= self.runningSeason[_tokenId]
  return (self.seasonData[_tokenId])[_seasonNo].harvestSupply

# @dev Return harvest price per unit supply
# @param _tokenId Tokenized farm ID
# @param _seasonNo Running season
# @return uint256
@external
@view
def harvestPrice(_tokenId: uint256, _seasonNo: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True
  assert _seasonNo <= self.runningSeason[_tokenId]
  return (self.seasonData[_tokenId])[_seasonNo].harvestPrice

# @dev Open season: Token should be in dormant state to open new season
# @param _tokenId Tokenized farm ID
@external
def openSeason(_tokenId: uint256):
  assert self.farmContract.getTokenState(_tokenId) == 'Dormant' # dev: is not dormant
  self.runningSeason[_tokenId] += 1
  self.farmContract.transitionState(_tokenId, 'Preparation', msg.sender) # dev: only owner can update state

# @dev Confirm preparations for new plantings
# @param _tokenId Tokenized farm ID
# @param _crop Crop for new plantings
# @param _preparationFertilizer Fertilizer used during preparation
# @param _preparationFertilizerSupplier Supplier of the preparation fertilizer
@external
def confirmPreparations(_tokenId: uint256, _crop: String[225], _preparationFertilizer: String[225], _preparationFertilizerSupplier: String[225]):
  assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm preparations
  assert self.farmContract.getTokenState(_tokenId) == 'Preparation' # dev: state is not preparations
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].crop = _crop
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].preparationFertilizer = _preparationFertilizer
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].preparationFertilizerSupplier = _preparationFertilizerSupplier
  # Transition state
  self.farmContract.transitionState(_tokenId, 'Planting', msg.sender)

# @dev Confirm planting
# @param _tokenId Tokenized farm ID
# @param _seedsUsed Seeds used during planting
# @param _seedsSupplier Seeds used supplier
# @param _expectedYield Seeds used expected yield
# @param _plantingFertilizer Fertilizer used during planting
# @param _plantingFertilizerSupplier Fertilizer supplier used during planting
@external
def confirmPlanting(_tokenId: uint256, _seedsUsed: String[225], _seedsSupplier: String[225], _expectedYield: String[50], _plantingFertilizer: String[225], _plantingFertilizerSupplier: String[225]):
  assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm planting
  assert self.farmContract.getTokenState(_tokenId) == 'Planting' # dev: state is not planting
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].seedsUsed = _seedsUsed
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].seedsSupplier = _seedsSupplier
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].expectedYield = _expectedYield
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].plantingFertilizer = _plantingFertilizer
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].plantingFertilizerSupplier = _plantingFertilizerSupplier
  # Transition state
  self.farmContract.transitionState(_tokenId, 'Crop Growth', msg.sender)

# @dev Confirm crop growth
# @param _tokenId Tokenized farm ID
# @param _pesticideUsed Pesticide used
# @param _pesticideSupplier Pesticide supplier
@external
def confirmGrowth(_tokenId: uint256, _pesticideUsed: String[225], _pesticideSupplier: String[225]):
  assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm crop growth
  assert self.farmContract.getTokenState(_tokenId) == 'Crop Growth' # dev: state is not crop growth
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].pesticideUsed = _pesticideUsed
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].pesticideSupplier = _pesticideSupplier
  # Transition state
  self.farmContract.transitionState(_tokenId, 'Harvesting', msg.sender)

# @dev Confirm harvesting
# @param _tokenId Tokenized farm ID
# @param _harvestSupply Total season harvest supply
# @param _harvestUnit Harvest supply unit
# @param _unitPrice Harvest price per unit
@external
def confirmHarvesting(_tokenId: uint256, _harvestSupply: uint256, _harvestUnit: String[100], _unitPrice: uint256):
  assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can confirm harvesting
  assert self.farmContract.getTokenState(_tokenId) == 'Harvesting' # dev: state is not harvesting
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].harvestSupply = _harvestSupply
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].harvestUnit = _harvestUnit
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].harvestPrice = _unitPrice
  # Hash season data after harvest confirmation
  _tr: uint256 = _tokenId + self.runningSeason[_tokenId]
  _trHash: bytes32 = convert(_tr, bytes32)
  _hash: bytes32 = keccak256(_trHash)
  (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].traceHash = _hash
  # Resolve season hash to season data
  self.seasonDataHash[_hash] = (self.seasonData[_tokenId])[self.runningSeason[_tokenId]]
  self.resolvedHashes[_hash] = True
  # Resolve hash to farm season
  (self.seasonHash[_tokenId])[self.runningSeason[_tokenId]] = _hash
  # Transition state
  self.farmContract.transitionState(_tokenId, 'Booking', msg.sender)

# @dev Query season data
# @param _tokenId Tokenized farm
# @param _index Season index
@external
@view
def querySeasonData(_tokenId: uint256, _index: uint256) -> SeasonData:
  assert self.farmContract.exists(_tokenId) == True
  assert _index <= self.runningSeason[_tokenId]
  return (self.seasonData[_tokenId])[_index]

# @dev Burn season supply
# @param _tokenId Tokenized farm ID
# @param _seasonNo Season number
# @param _volume Volume to burn
# Throw if `_seasonNo > currentSeason(_tokenId)`
# Throw if `_volume > (self.seasonData[_tokenId])[_seasonNo]`
@internal
def burnSupply(_tokenId: uint256, _seasonNo: uint256, _volume: uint256):
  assert self.farmContract.getTokenState(_tokenId) == 'Booking' # dev: not harvesting to burn supply
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  assert _volume <= (self.seasonData[_tokenId])[_seasonNo].harvestSupply # dev: volume greater than available supply
  assert _seasonNo <= self.runningSeason[_tokenId] # dev: season number out of range
  (self.seasonData[_tokenId])[_seasonNo].harvestSupply -= _volume

# @dev Mint season supply
# @param _tokenId Tokenized farm ID
# @param _seasonNo Season number
# @param _volume Volume to burn
# Throw if `_seasonNo > currentSeason(_tokenId)`
# Throw if `_volume > (self.seasonSupply[_tokenId])[_seasonNo]`
@internal
def mintSupply(_tokenId: uint256, _seasonNo: uint256, _volume: uint256):
  assert self.farmContract.getTokenState(_tokenId) == 'Harvesting' # dev: not harvesting to mint supply
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  assert _seasonNo <= self.runningSeason[_tokenId] # dev: season number out of range
  (self.seasonData[_tokenId])[_seasonNo].harvestSupply += _volume

# @dev Book season harvest: burn season supply
# @dev Index booking to farm
# @dev Index booking to booker
# @dev Update season supply after booking
# Throw if `_volume` == 0 or `_volume > harvestSupply`
# Throw if `msg.value` != `unitPrice * _volume` : insufficient funds
# Throw if `msg.sender` == `ownerOf(_tokenId)`: owner cannot book his/her harvest
# Throw if `getSeason(_tokenId)` != `Harvesting`
# @param _tokenId Tokenized farm id
# @param _volume Amount to book
# @param _seasonNo Season number
@external
@payable
def bookHarvest(_tokenId: uint256, _volume: uint256, _seasonNo: uint256):
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  assert self.farmContract.getTokenState(_tokenId) == 'Booking' # dev: season not booking
  assert msg.sender != self.farmContract.ownerOf(_tokenId) # dev: owner cannot book his/her harvest
  assert _volume != 0 # dev: volume cannot be 0
  assert _volume <= (self.seasonData[_tokenId])[_seasonNo].harvestSupply
  assert msg.value == (self.seasonData[_tokenId])[_seasonNo].harvestPrice * _volume # dev: insufficient booking funds
  # Store booker bookings
  _runningSeason: uint256 = self.runningSeason[_tokenId]
  previousVolume: uint256 = (self.bookerBookings[msg.sender])[_runningSeason].volume
  (self.bookerBookings[msg.sender])[_runningSeason].volume += _volume
  (self.bookerBookings[msg.sender])[_runningSeason].delivered = False
  (self.bookerBookings[msg.sender])[_runningSeason].cancelled = False
  (self.bookerBookings[msg.sender])[_runningSeason].deposit += msg.value
  (self.bookerBookings[msg.sender])[_runningSeason].booker = msg.sender
  self.burnSupply(_tokenId, _runningSeason, _volume)
  # Increment booker total bookings
  if previousVolume == 0:
    self.totalBookerBookings[msg.sender] += 1
  # Index seasons booked
  (self.seasonsBooked[msg.sender])[self.totalBookerBookings[msg.sender]] = _runningSeason
  # Store farm bookings
  if previousVolume == 0:
    self.totalFarmBooking[_tokenId] += 1
  (self.farmBookings[_tokenId])[self.totalFarmBooking[_tokenId]] = (self.bookerBookings[msg.sender])[_runningSeason]

# @dev Burn booking
# @param _tokenId Tokenized farm id
# @param _booker Booker address
# @param _seasonNo Season number
# Throw if `(bookerBookings[_booker])[_seasonNo].volume == 0`
# Throw if `_seasonNo > self.season.currentSeason(_tokenId)`
# Throw if `self.farmContract.exists(_tokenId) == False`
# Throw if `_volume != 0`
@internal
def burnBooking(_tokenId: uint256, _booker: address, _seasonNo: uint256, _volume: uint256) -> uint256:
  assert _volume != 0 # dev: volume cannot be 0
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  assert (self.bookerBookings[_booker])[_seasonNo].volume != 0 # dev: no bookings
  assert _seasonNo <= self.runningSeason[_tokenId] # dev: invalid season
  # Update booker volume
  (self.bookerBookings[_booker])[_seasonNo].volume -= _volume
  # Update booker deposit
  burningDeposit: uint256 = (self.seasonData[_tokenId])[_seasonNo].harvestPrice * _volume
  (self.bookerBookings[_booker])[_seasonNo].deposit -= burningDeposit
  # Farm overdues
  return burningDeposit

# @dev Confirm receivership
# @param _tokenId Tokenized farm id
# @param _volume Booking volume to confirm
# @param _seasonNo Season number
# @param _provider Service provider
# @param _farmer Farm beneficiary
# Throw if `_volume > (bookerBooking[msg.sender])[_seasonNo].volume`
# Throw if `_volume == 0`
# Throw if `registryInterface.exists(_tokenId) == False`
# Throw if `_seasonNo > seasonInterface.currentSeason(_tokenId)`
@external
def confirmReceivership(_tokenId: uint256, _volume: uint256, _seasonNo: uint256, _farmer: address):
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  assert (self.bookerBookings[msg.sender])[_seasonNo].volume != 0 # dev: no bookings
  assert _volume <= (self.bookerBookings[msg.sender])[_seasonNo].volume
  farmOverdues: uint256 = 0
  farmOverdues = self.burnBooking(_tokenId, msg.sender, _seasonNo, _volume)
  # Transfer dues
  send(_farmer, farmOverdues)
  # Update delivered booking for booker
  self.bookerDelivery[msg.sender] += 1
  # Update delivered booking for farm
  self.tokenizedFarmDelivery[_tokenId] += 1
  # Update total receivership
  self.completedDelivery += 1
  # Log event
  log Receivership((self.bookerBookings[msg.sender])[_seasonNo].volume, (self.bookerBookings[msg.sender])[_seasonNo].deposit)

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
  assert self.farmContract.getTokenState(_tokenId) == 'Harvesting' # dev: is not harvesting
  assert (self.seasonData[_tokenId])[self.runningSeason[_tokenId]].harvestSupply == 0 # dev: supply is not exhausted
  self.farmCompleteSeason[_tokenId] += 1
  self.totalCompletedSeasons += 1
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
  self.hashTraces[_hash] += 1
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
  return (self.seasonHash[_tokenId])[_seasonNo]

