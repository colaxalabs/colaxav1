# @version ^0.2.0

# External Interfaces
interface Frmregistry:
  def ownerOf(_tokenId: uint256) -> address: view
  def exists(_tokenId: uint256) -> bool: view

interface Season:
  def getSeason(_tokenId: uint256) -> String[20]: view

# @dev Market
struct Market:
  price: uint256
  supplyUnit: String[2]
  active: bool
  open: bool
  openDate: uint256
  closeDate: uint256
  originalSupply: uint256
  remainingSupply: uint256
  bookers: uint256

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

# @dev Enlisted marketplace: index => Market
enlistedMarkets: HashMap[uint256, Market]

# @dev Farm market: tokenId => Market
farmMarket: HashMap[uint256, Market]

# @dev Farm market ID: tokenId => marketId
marketId: HashMap[uint256, uint256]

# @dev Total farm previous markets: tokenId => totalPrevMarkets
totalPrevMarkets: HashMap[uint256, uint256]

# @dev Farm previous markets: tokenId => index => Market
previousMarkets: HashMap[uint256, HashMap[uint256, Market]]

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

# @dev Farm goes to market
# @param _tokenId Tokenized farm ID
# @param _price Price of commodity per supply unit
# @param _supply Supply
# @param _unit Supply unit(kilogram)
@external
def createMarket(_tokenId: uint256, _price: uint256, _supply: uint256, _unit: String[2]):
  assert self.farmContract.exists(_tokenId) == True # dev: invalid tokenized farm
  assert self.farmContract.ownerOf(_tokenId) == msg.sender # dev: only owner can create market
  assert self.seasonContract.getSeason(_tokenId) == 'Harvesting'
  assert self.farmMarket[_tokenId].remainingSupply == 0 # dev: exhaust previous market supply
  # Market count
  self.markets += 1
  # Farm market ID
  self.marketId[_tokenId] = self.markets
  # Store market
  self.farmMarket[_tokenId] = Market({
    price: _price,
    supplyUnit: _unit,
    originalSupply: _supply,
    remainingSupply: _supply,
    active: True,
    open: True,
    openDate: block.timestamp,
    closeDate: 0,
    bookers: 0
  })
  # Update enlisted markets
  self.enlistedMarkets[self.markets] = self.farmMarket[_tokenId]

# @dev Get enlisted market
# @param _index Index of the market
# Throw if `_index > markets(totalMarkets)`
# @return Market
@external
@view
def getEnlistedMarket(_index: uint256) -> Market:
  assert _index <= self.markets # dev: index out of range
  return self.enlistedMarkets[_index]

