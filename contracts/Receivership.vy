# @version ^0.2.0

# External interface
interface Frmregistry:
    def exists(_tokenId: uint256) -> bool: view

interface Booking:
  def burnBooking(_tokenId: uint256, _booker: address, _seasonNo: uint256, _volume: uint256, _provider: address, _farmer: address): nonpayable
  def bookerVolume(_booker: address, _seasonNo: uint256) -> uint256: view
  def bookerDeposit(_booker: address, _seasonNo: uint256) -> uint256: view

# Events
event Receivership:
  volume: uint256
  deposit: uint256

# @dev Booking contract
bookingContract: Booking

# Farm registry contract
farmContract: Frmregistry

# @dev Cancelled bookings(booker)
bookerCancellation: HashMap[address, uint256]

# @dev Cancelled bookings(tokenized farm)
tokenizedFarmCancellation: HashMap[uint256, uint256]

# @dev Total completed delivery
completedDelivery: uint256

# @dev Delivered bookings for booker
bookerDelivery: HashMap[address, uint256]

# @dev Delivered bookings for tokenized farm
tokenizedFarmDelivery: HashMap[uint256, uint256]

@external
def __init__(bookingContract_address: address, farmContract_address: address):
  self.bookingContract = Booking(bookingContract_address)
  self.farmContract = Frmregistry(farmContract_address)

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

# @dev Get total cancellation for booker
# @param _address Booker address
# Throw if `_address == ZERO_ADDRESS`
@external
@view
def totalCancellationForBooker(_address: address) -> uint256:
  assert _address != ZERO_ADDRESS # dev: invalid address
  return self.bookerCancellation[_address]

# @dev Get total cancellation for tokenized farm
# @param _tokenId Tokenized farm id
# Throw if `_tokenId == False`
@external
@view
def totalCancellationForFarm(_tokenId: uint256) -> uint256:
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  return self.tokenizedFarmCancellation[_tokenId]

# @dev Confirm receivership
# @param _tokenId Tokenized farm id
# @param _volume Booking volume to cancel
# @param _seasonNo Season number
# @param _provider Service provider
# Throw if `_volume > (bookerBooking[msg.sender])[_seasonNo].volume`
# Throw if `_volume == 0`
# Throw if `registryInterface.exists(_tokenId) == False`
# Throw if `_seasonNo > seasonInterface.currentSeason(_tokenId)`
@external
def confirmReceivership(_tokenId: uint256, _volume: uint256, _seasonNo: uint256, _provider: address, _farmer: address):
  assert self.farmContract.exists(_tokenId) == True # dev: invalid token id
  assert self.bookingContract.bookerVolume(msg.sender, _seasonNo) != 0 # dev: no bookings
  assert _volume <= self.bookingContract.bookerVolume(msg.sender, _seasonNo)
  self.bookingContract.burnBooking(_tokenId, msg.sender, _seasonNo, _volume, _provider, _farmer)
  # Update delivered booking for booker
  self.bookerDelivery[msg.sender] += 1
  # Update delivered booking for farm
  self.tokenizedFarmDelivery[_tokenId] += 1
  # Update total receivership
  self.completedDelivery += 1
  # Log event
  log Receivership(self.bookingContract.bookerVolume(msg.sender, _seasonNo), self.bookingContract.bookerDeposit(msg.sender, _seasonNo))

