# @version ^0.2.0

# External Interfaces
interface Season:
    def completeSeasons() -> uint256: view
    def getSeason(_tokenId: uint256) -> String[20]: view
    def getSeasonSupply(_tokenId: uint256, _seasonNo: uint256) -> uint256: view
    def currentSeason(_tokenId: uint256) -> uint256: view
    def harvestPrice(_tokenId: uint256, _seasonNo: uint256) -> uint256: view

interface Frmregistry:
    def exists(_tokenId: uint256) -> bool: view
    def ownerOf(_tokenId: uint256) -> address: view

# @dev Farm registry contract
farm_registry: Frmregistry

# @dev Season contract
season: Season

# Booking type
struct Booking:
  volume: uint256
  delivered: bool
  cancelled: bool
  booker: address
  deposit: uint256

# @dev Total completed bookings
totalBookings: uint256

# @dev Index all bookings to tokenized farm
totalFarmBooking: HashMap[uint256, uint256] # token => total number of farm bookings
farmBookings: HashMap[uint256, HashMap[uint256, Booking]] # token => farmBooking[token]: index => Booking{}

# @dev Index all bookings to address
totalBookerBookings: HashMap[address, uint256] # address => total number of booker bookings
bookerBookings: HashMap[address, HashMap[uint256, Booking]] # address => seasonNo[_tokenId]: index => Booking{}
seasonsBooked: HashMap[address, HashMap[uint256, uint256]] # seasons booked indexed by totalBookerBookings

# @dev Cancelled bookings(booker)
bookerCancellation: HashMap[address, uint256]

# @dev Cancelled bookings(tokenized farm)
tokenizedFarmCancellation: HashMap[uint256, uint256]

# @dev Delivered bookings(booker)
bookerDelivered: HashMap[address, uint256]

# @dev Delivered bookings(tokenized farm)
tokenizedFarmDelivered: HashMap[uint256, uint256]

# @dev Season bookings(for analytics)
seasonalBookings: HashMap[uint256, uint256] # season => number of season bookings

@external
def __init__(farm_contract_address: address, season_contract_address: address):
  self.farm_registry = Frmregistry(farm_contract_address)
  self.season = Season(season_contract_address)

# @dev Return total completed bookings
@external
@view
def completedBookings() -> uint256:
  return self.totalBookings

# @dev Return farm total bookings
# @param _tokenId Tokenized farm ID
@external
@view
def totalFarmBookings(_tokenId: uint256) -> uint256:
  assert self.farm_registry.exists(_tokenId) == True # dev: invalid token id
  return self.totalFarmBooking[_tokenId]

# @dev Get farm booking
# @param _tokenId Tokenized farm ID
# @param _index Booking index
# @return Booking
@external
@view
def getFarmBooking(_tokenId: uint256, _index: uint256) -> Booking:
  assert self.farm_registry.exists(_tokenId) == True # dev: invalid token id
  assert _index <= self.totalFarmBooking[_tokenId] # dev: out of range index
  return (self.farmBookings[_tokenId])[_index]

# @dev Get total booker bookings
# @param _address Booker address
@external
@view
def totalBookerBooking(_address: address) -> uint256:
  assert _address != ZERO_ADDRESS # dev: invalid address
  return self.totalBookerBookings[_address]

# @dev Get booker booking
# @param _address Booker address
# @param _index Booking index
@external
@view
def getBookerBooking(_address: address, _index: uint256) -> Booking:
  assert _address != ZERO_ADDRESS # dev: invalid address
  assert _index <= self.totalBookerBookings[_address] # dev: out of range index
  return (self.bookerBookings[_address])[_index]

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
  assert self.farm_registry.exists(_tokenId) == True # dev: invalid token id
  assert self.season.getSeason(_tokenId) == 'Booking' # dev: season not booking
  assert msg.sender != self.farm_registry.ownerOf(_tokenId) # dev: owner cannot book his/her harvest
  assert _volume != 0 # dev: volume cannot be 0
  assert _volume <= self.season.getSeasonSupply(_tokenId, _seasonNo)
  assert msg.value == (self.season.harvestPrice(_tokenId, _seasonNo) * _volume) # dev: insufficient booking funds
  # Store booker bookings
  _runningSeason: uint256 = self.season.currentSeason(_tokenId)
  (self.bookerBookings[msg.sender])[_runningSeason] = Booking({
    volume: _volume,
    delivered: False,
    cancelled: False,
    booker: msg.sender,
    deposit: msg.value,
  })
  self.totalBookerBookings[msg.sender] += 1
  # Index seasons booked
  (self.seasonsBooked[msg.sender])[self.totalBookerBookings[msg.sender]] = _runningSeason
  # Store farm bookings
  self.totalFarmBooking[_tokenId] += 1
  (self.farmBookings[_tokenId])[self.totalFarmBooking[_tokenId]] = (self.bookerBookings[msg.sender])[_runningSeason]

