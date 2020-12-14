# @version ^0.2.0

# External Interfaces
interface Frmregistry:
  def ownerOf(_tokenId: uint256) -> address: view
  def exists(_tokenId: uint256) -> bool: view

interface Season:
  def getSeason(_tokenId: uint256) -> String[20]: view
  def currentSeason(_tokenId: uint256) -> uint256: view
  def hashedSeason(_tokenId: uint256, _seasonNo: uint256) -> bytes32: view

# @dev Market
struct Market:
  price: uint256
  supplyUnit: String[2]
  openDate: uint256
  closeDate: uint256
  originalSupply: uint256
  remainingSupply: uint256
  bookers: uint256

# @dev Book
struct Book:
  volume: uint256
  delivered: bool
  booker: address
  deposit: uint256
  season: uint256
  date: uint256
  marketId: uint256
  harvestId: bytes32

# @dev Market fee
MARKET_FEE: constant(uint256) = as_wei_value(0.0037, 'ether')

# @dev Sealed platform tx
platformTx: uint256

# @dev Sealed user tx
accountTx: HashMap[address, uint256]

# @dev Sealed farm tx
farmTx: HashMap[uint256, uint256]

# @dev Registry contract
farmContract: Frmregistry

# @dev Season contract
seasonContract: Season

# @dev Total number of markets
markets: uint256

# @dev Season went to market farm => season => True/False
marketedSeason: HashMap[uint256, HashMap[uint256, bool]]

# @dev Enlisted marketplace: index => Market
enlistedMarkets: HashMap[uint256, Market]

# @dev Farm market: tokenId => Market
farmMarket: HashMap[uint256, Market]

# @dev Is market for farm created
isMarket: HashMap[uint256, bool]

# @dev Farm market ID: tokenId => marketId
marketId: HashMap[uint256, uint256]

# @dev Total farm previous markets: tokenId => totalPrevMarkets
totalPrevMarkets: HashMap[uint256, uint256]

# @dev Farm previous markets: tokenId => index => Market
previousMarkets: HashMap[uint256, HashMap[uint256, Market]]

# @dev Index all bookings to address
totalBookerBookings: HashMap[address, uint256] # address => total number of booker bookings
bookerBooking: HashMap[address, HashMap[uint256, Book]] # address => seasonNo: index => Booking{}
seasonsBooked: HashMap[address, HashMap[uint256, uint256]] # seasons booked indexed by totalBookerBookings
bookedSeason: HashMap[address, HashMap[uint256, bool]] # Season booked mapped to True of False

# @dev Delivered bookings for platform, market, and booker
bookerDelivery: HashMap[address, uint256]
marketDelivery: HashMap[uint256, uint256]
completedDelivery: uint256

# @dev Market booking: market => index => Book
marketBooking: HashMap[uint256, HashMap[uint256, Book]]
# @dev Index market bookings
marketBookingIndex: HashMap[uint256, HashMap[uint256, uint256]]

# @dev Defaults
@external
def __init__(registry_contract_address: address, season_contract_address: address):
  self.farmContract = Frmregistry(registry_contract_address)
  self.seasonContract = Season(season_contract_address)

# @dev Get total deal sealed on the platform
# @return uint256
@external
@view
def platformTransactions() -> uint256:
  return self.platformTx

# @dev Get total deals sealed for an account/user
# @param _address User account address
# Throw if `_address != ZERO_ADDRESS`
# @return uint256
@external
@view
def userTransactions(_address: address) -> uint256:
  assert _address != ZERO_ADDRESS
  return self.accountTx[_address]

# @dev Get total deal sealed for a farm
# @param _tokenId Tokenized farm ID
# Throw if `farmContract.exists(_tokenId) == False`
# @return uint256
@external
@view
def farmTransactions(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True
  return self.farmTx[_tokenId]

# @dev Check if a season has gone to market
# @param _tokenId Tokenized farm ID
# @param _seasonNo Current farm season number
@external
@view
def isSeasonMarketed(_tokenId: uint256, _seasonNo: uint256) -> bool:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid tokenized farm id
  assert _seasonNo <= self.seasonContract.currentSeason(_tokenId) # dev: season number out of range
  return self.marketedSeason[_tokenId][_seasonNo]

# @dev Get total markets
# @return uint256
@external
@view
def totalMarkets() -> uint256:
  return self.markets

# @dev Get total previous markets
# @param _tokenId Tokenized farm ID
# Throw if `farmContract.exists(_tokenId) == False`
# @return uint256
@external
@view
def farmPrevMarkets(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid tokenized farm
  return self.totalPrevMarkets[_tokenId]

# @dev Get previous market belonging to a farm
# @param _tokenId Tokenized farm ID
# @param _index Index in mapping variable
# Throw if `farmContract.exists(_tokenId) == False`
# Throw if `_index > self.totalPrevMarkets[_tokenId]`
# @return Market
@external
@view
def getFarmPrevMarket(_tokenId: uint256, _index: uint256) -> Market:
  assert self.farmContract.exists(_tokenId) == True
  assert _index <= self.totalPrevMarkets[_tokenId]
  return (self.previousMarkets[_tokenId])[_index]

# @dev Get current market for a farm
# @param _tokenId Tokenized farm ID
# Throw if `farmContract.exists(_tokenId) == False`
# @return Market
@external
@view
def getCurrentFarmMarket(_tokenId: uint256) -> Market:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid tokenized farm
  return self.farmMarket[_tokenId]

# @dev Get market booking
# @param _tokenId Tokenized farm market ID
# @param _index Index of the market in mapping
# Throw if `farmContract.exists(_tokenId) == False`
# Throw if `_index > self.farmMarket[_tokenId].bookers`
@external
@view
def getMarketBooking(_tokenId: uint256, _index: uint256) -> Book:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid tokenized farm id
  assert _index <= self.farmMarket[_tokenId].bookers # dev: index out of range
  return (self.marketBooking[_tokenId])[_index]

# @dev Farm goes to market
# @param _tokenId Tokenized farm ID
# @param _price Price of commodity per supply unit
# @param _supply Supply
# @param _unit Supply unit(kilogram)
@external
def createMarket(_tokenId: uint256, _price: uint256, _supply: uint256, _unit: String[2]):
  assert self.farmContract.exists(_tokenId) == True # dev: invalid tokenized farm
  assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can create market
  assert self.seasonContract.getSeason(_tokenId) == 'Marketing'
  assert self.farmMarket[_tokenId].remainingSupply == 0 # dev: exhaust previous market supply
  # Market count
  if self.isMarket[_tokenId] == False:
    self.markets += 1
    self.marketId[_tokenId] = self.markets
    self.isMarket[_tokenId] = True
  # Store market
  self.farmMarket[_tokenId] = Market({
    price: _price,
    supplyUnit: _unit,
    originalSupply: _supply,
    remainingSupply: _supply,
    openDate: block.timestamp,
    closeDate: 0,
    bookers: 0
  })
  # Marketed seasons
  self.marketedSeason[_tokenId][self.seasonContract.currentSeason(_tokenId)] = True
  # Update enlisted markets
  self.enlistedMarkets[self.marketId[_tokenId]] = self.farmMarket[_tokenId]

# @dev Get enlisted market
# @param _index Index of the market
# Throw if `_index > markets(totalMarkets)`
# @return Market
@external
@view
def getEnlistedMarket(_index: uint256) -> Market:
  assert _index <= self.markets # dev: index out of range
  return self.enlistedMarkets[_index]

# @dev Mint season supply
# @param _tokenId Tokenized farm ID
# @param _volume Volume to burn
# @internal
# def mintSupply(_tokenId: uint256, _volume: uint256):
  # self.farmMarket[_tokenId].remainingSupply += _volume

# @dev Get total booker bookings
# @param _address Booker address
@external
@view
def totalBookerBooking(_address: address) -> uint256:
  assert _address != ZERO_ADDRESS # dev: invalid address
  return self.totalBookerBookings[_address]

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
def getBookerBooking(_seasonIndex: uint256, _booker: address) -> Book:
  assert _booker != ZERO_ADDRESS
  return (self.bookerBooking[_booker])[_seasonIndex]

# @dev Get total market bookings
# @param _tokenId Tokenized farm market ID
# @return uint256
# Throw if `farmContract.exists(_tokenId) == False`
@external
@view
def totalMarketBookers(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid tokenized farm id
  return self.farmMarket[_tokenId].bookers

# @dev Burn season supply
# @param _tokenId Tokenized farm ID
# @param _volume Volume to burn
@internal
def burnSupply(_tokenId: uint256, _volume: uint256):
  self.farmMarket[_tokenId].remainingSupply -= _volume
  if self.farmMarket[_tokenId].remainingSupply == 0:
    self.totalPrevMarkets[_tokenId] += 1
    (self.previousMarkets[_tokenId])[self.totalPrevMarkets[_tokenId]] = self.farmMarket[_tokenId]

# @dev Book season harvest: burn season supply
# @dev Index booking to farm
# @dev Index booking to booker
# @dev Update season supply after booking
# Throw if `_volume == 0 or _volume > harvestSupply`
# Throw if `msg.value != unitPrice * _volume` : insufficient funds
# Throw if `msg.sender == ownerOf(_tokenId)`: owner cannot book his/her harvest
# Throw if `getSeason(_tokenId) != Harvesting`
# @param _tokenId Tokenized farm id
# @param _volume Amount to book
# @param _seasonNo Season number
@external
@payable
def bookHarvest(_tokenId: uint256, _volume: uint256, _seasonNo: uint256):
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  assert msg.sender != self.farmContract.ownerOf(_tokenId) # dev: owner cannot book his/her harvest
  assert _volume != 0 # dev: volume cannot be 0
  assert _volume <= self.farmMarket[_tokenId].remainingSupply
  assert msg.value != as_wei_value(0, 'ether') # dev: booking funds cannot be 0
  assert msg.value == self.farmMarket[_tokenId].price * _volume # dev: insufficient booking funds
  # Store booker bookings
  _runningSeason: uint256 = self.seasonContract.currentSeason(_tokenId)
  _harvestId: bytes32 = self.seasonContract.hashedSeason(_tokenId, _runningSeason)
  (self.bookerBooking[msg.sender])[_runningSeason].date = block.timestamp
  (self.bookerBooking[msg.sender])[_runningSeason].volume += _volume
  (self.bookerBooking[msg.sender])[_runningSeason].delivered = False
  (self.bookerBooking[msg.sender])[_runningSeason].deposit += msg.value
  (self.bookerBooking[msg.sender])[_runningSeason].booker = msg.sender
  (self.bookerBooking[msg.sender])[_runningSeason].marketId = _tokenId
  (self.bookerBooking[msg.sender])[_runningSeason].season = _seasonNo
  (self.bookerBooking[msg.sender])[_runningSeason].harvestId = _harvestId
  # Increment booker total bookings
  if (self.bookedSeason[msg.sender])[_runningSeason] == False:
    self.farmMarket[_tokenId].bookers += 1
    self.totalBookerBookings[msg.sender] += 1
    (self.bookedSeason[msg.sender])[_runningSeason] = True
  # Burn supply
  self.burnSupply(_tokenId, _volume)
  # Index seasons booked
  (self.seasonsBooked[msg.sender])[self.totalBookerBookings[msg.sender]] = _runningSeason
  # Index market booking
  (self.marketBookingIndex[_tokenId])[_runningSeason] = self.farmMarket[_tokenId].bookers
  (self.marketBooking[_tokenId])[self.farmMarket[_tokenId].bookers] = (self.bookerBooking[msg.sender])[_runningSeason]

# @dev Burn booker booking
# @param _tokenId Tokenized farm ID
# @param _booker Booker address
# @param _seasonNo Season booked
# @param _volume Volume to burn
@internal
def burnBooking(_tokenId: uint256, _booker: address, _seasonNo: uint256, _volume: uint256) -> (uint256, uint256, uint256):
  burningDeposit: uint256 = self.farmMarket[_tokenId].price * _volume
  # Burn booker deposit
  (self.bookerBooking[_booker])[_seasonNo].deposit -= burningDeposit
  # Burn booker volume
  (self.bookerBooking[_booker])[_seasonNo].volume -= _volume
  # Calculate farm dues
  farmDues: uint256 = burningDeposit - MARKET_FEE
  # Calculate provider fee
  providerFee: uint256 = burningDeposit - farmDues
  # Return farm overdues
  return burningDeposit, farmDues, providerFee

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
@payable
def confirmReceivership(_tokenId: uint256, _volume: uint256, _seasonNo: uint256, _farmer: address, _provider: address):
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  assert _volume != 0 # dev: volume cannot be 0
  assert (self.bookerBooking[msg.sender])[_seasonNo].volume != 0 # dev: no bookings
  assert _volume <= (self.bookerBooking[msg.sender])[_seasonNo].volume # dev: volume out of range
  assert msg.value == MARKET_FEE # dev: insufficient confirmation fee
  burningDeposit: uint256 = 0
  farmDues: uint256 = 0
  providerFee: uint256 = 0
  (burningDeposit, farmDues, providerFee) = self.burnBooking(_tokenId, msg.sender, _seasonNo, _volume)
  # Update seal deals tx
  self.farmTx[_tokenId] += burningDeposit - MARKET_FEE
  self.accountTx[msg.sender] += burningDeposit - MARKET_FEE
  self.platformTx += burningDeposit - MARKET_FEE
  # Update delivered booking for booker
  self.bookerDelivery[msg.sender] += 1
  # Update delivered booking for farm market
  self.marketDelivery[_tokenId] += 1
  # Update total receivership
  self.completedDelivery += 1
  # Transfer dues
  send(_farmer, farmDues)
  send(_provider, providerFee)
  # Log event
  # log Receivership((self.bookerBookings[msg.sender])[_seasonNo].volume, (self.bookerBookings[msg.sender])[_seasonNo].deposit)

# @dev Get total delivery for an account
# @param _address Address of the account
# @return uint256
@external
@view
def accountDeliverables(_address: address) -> uint256:
  return self.bookerDelivery[_address]

# @dev Get total delivery for a tokenized farm
# @param _tokenId Tokenized farm id
# Throw if `farmContract.exists(_tokenId) == False`
# @return uint256
@external
@view
def farmDeliverables(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid tokenized farm id
  return self.marketDelivery[_tokenId]

