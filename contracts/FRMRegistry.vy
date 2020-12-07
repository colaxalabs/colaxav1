# @version ^0.2.0

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
  def onERC721Received(_operator: address, _from: address, _tokenId: uint256, _data: Bytes[1024]) -> bytes32: view

# Events

event Transfer:
  _from: indexed(address)
  _to: indexed(address)
  _tokenId: indexed(uint256)

event Approval:
  _owner: indexed(address)
  _approved: indexed(address)
  _tokenId: indexed(uint256)

event ApprovalForAll:
  _owner: indexed(address)
  _operator: indexed(address)
  _approved: bool

event Tokenize:
  _owner: indexed(address)
  _tokenId: indexed(uint256)
  _name: String[100]

# @dev Farm type
struct Farm:
  tokenId: uint256
  name: String[100]
  size: String[20]
  location: String[225]
  imageHash: String[255]
  soil: String[20]
  season: String[20]
  owner: address
  userIndex: uint256
  platformIndex: uint256

# @dev Map token to Farm
tokenizedFarms: HashMap[uint256, Farm]

# Total tokenized lands
tokenizedLands: uint256

# @dev Index tokenized farms
indexedTokenizedFarms: HashMap[uint256, Farm]

# @dev Mapping for supported interfaces
supportedInterfaces: HashMap[bytes32, bool]

# @dev Mapping NFTs to their address owner
idToOwner: HashMap[uint256, address]

# @dev Mapping NFTs to their approved address
idToApprovals: HashMap[uint256, address]

# @dev Mapping address to number of owned ID to NFT
ownedNFT: HashMap[address, HashMap[uint256, Farm]]

# @dev Mapping number of owned NFT to address
ownerNFTCount: HashMap[address, uint256]

# Token name
tokenName: String[10]

# Token symbol
tokenSymbol: String[3]

# Token base URI
tokenURI: String[255]

# @dev Mapping NFT owner to approved operator address
ownerAddressToOperator: HashMap[address, HashMap[address, bool]]

# @dev Address of minter, who can mint a token
minter: address

# @dev ERC165 interface ID of ERC165
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7

# @dev ERC165 interface ID of ERC721
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd

# FUNCTIONS 

@external
def __init__():
  self.tokenName = 'Reap'
  self.tokenSymbol = 'REA'
  # The interface ID of supportedInterfaces
  self.supportedInterfaces[ERC165_INTERFACE_ID] = True
  self.supportedInterfaces[ERC721_INTERFACE_ID] = True
  self.minter = msg.sender

# @dev Return token name
@external
@view
def name() -> String[10]:
  return self.tokenName

# @dev Return token symbol
@external
@view
def symbol() -> String[3]:
  return self.tokenSymbol

# @dev Return token base URI
@external
@view
def baseURI() -> String[255]:
  return self.tokenURI

# @dev Return token total supply
@external
@view
def totalSupply() -> uint256:
  return self.tokenizedLands

# @dev Return total tokenized farm lands
@external
@view
def totalTokenizedLands() -> uint256:
  return self.tokenizedLands

# @dev Function to check which interface this contract supports
# @param _interfaceId Id of the interface
@view
@external
def supportsInterface(_interfaceId: bytes32) -> bool:
  return self.supportedInterfaces[_interfaceId]

# @dev Returns the number of NFT owned by address
# NFT assigned to ZERO_ADDRESS is considered invalid
# @param _owner Address for whom to check balance
@view
@external
def balanceOf(_owner: address) -> uint256:
  assert _owner != ZERO_ADDRESS
  return self.ownerNFTCount[_owner]

# @dev Returns the address owning the NFT
# @param _tokenId ID to check owner
@view
@external
def ownerOf(_tokenId: uint256) -> address:
  assert self.idToOwner[_tokenId] != ZERO_ADDRESS
  return self.idToOwner[_tokenId]

# @dev Get the approved address for an NFT
# @notice Throw if NFT is not valid
# @param _tokenId ID of the NFT to get approval of
@view
@external
def getApproved(_tokenId: uint256) -> address:
  assert self.idToOwner[_tokenId] != ZERO_ADDRESS
  return self.idToApprovals[_tokenId]

# @dev Check if operator address is an approved operator for NFT owner address
# @param _owner Owner of the NFT
# @param _operator The address that acts on behalf of the owner
@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
  if _owner == ZERO_ADDRESS:
    return False
  return (self.ownerAddressToOperator[_owner])[_operator]

# TRANSFER HELPER FUNCTIONS

# @dev Check whether the given address is the owner or the approved operator
# of a given token ID
# @param _spender Address of the spender to query
# @param _tokenId Token to transfer
@internal
@view
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
  owner: address = self.idToOwner[_tokenId]
  spenderIsOwner: bool = owner == _spender
  spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
  spenderIsApprovedForAll: bool = (self.ownerAddressToOperator[owner])[_spender]
  return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll

# @dev Add NFT to `_to`
# Throws if `_tokenId` is owned by someone
@internal
def _addToken(_to: address, _tokenId: uint256):
  # Check if token is already taken
  assert self.idToOwner[_tokenId] == ZERO_ADDRESS
  # Update owner
  self.idToOwner[_tokenId] = _to
  # Update NFT owner count
  self.ownerNFTCount[_to] += 1

# @dev Remove token from a given address
# Throws if `_from` is not the current owner
@internal
def _removeToken(_from: address, _tokenId: uint256):
  # Check if `_from` is the current owner
  assert self.idToOwner[_tokenId] == _from
  # Update owner
  self.idToOwner[_tokenId] = ZERO_ADDRESS
  # Update NFT owner count
  self.ownerNFTCount[_from] -= 1

# @dev Clear an approval of a given address
# Throws if `_owner` is not the current owner
@internal
def _clearApproval(_owner: address, _tokenId: uint256):
  # Check if `_owner` is the current owner
  assert self.idToOwner[_tokenId] == _owner
  if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
    # Reset approvals
    self.idToApprovals[_tokenId] = ZERO_ADDRESS

# @dev Transfer mechanism
# @param _to Receiver address
# @param _from Sender address
# @param _tokenId NFT to transfer from `_from` to `_to`
# @param _sender Placeholder for `msg.sender`
# Throws unless `msg.sender` is the current owner, an authorized
# operator, or the approved address for this NFT. (NOTE: `msg.sender`
# is not allowed in private/internal functions)
# Throws if `_to` is the ZERO_ADDRESS
# Throws if `_from` is not the current owner
# Throws if `_tokenId` is not a valid NFT
@internal
def _transferMechanism(_to: address, _from: address, _tokenId: uint256, _sender: address):
  # Check _sender(msg.sender) is owner, an authorized operator, or the approves address
  assert self._isApprovedOrOwner(_sender, _tokenId)
  # Throws if `_to` is the ZERO_ADDRESS
  assert _to != ZERO_ADDRESS
  # Clear approvals. Throws if `_from` is not the current owner
  self._clearApproval(_from, _tokenId)
  # Remove NFT. Throws if `_tokenId` is not valid
  self._removeToken(_from, _tokenId)
  # Add NFT
  self._addToken(_to, _tokenId)
  # Log Transfer Mechanism
  log Transfer(_from, _to, _tokenId)

# @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
# TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTs OR ELSE THEY
# MAY BE PERMANENTLY LOST
# @dev Throws unless `msg.sender` is the current owner, an authorized
# operator, or the approved address for this NFT. Throws if `_from` is
# not the current owner. Throws if `_to` is the ZERO_ADDRESS. Throws if
# `_tokenId` is not a valid NFT.
# @param _from The current owner of the NFT
# @param _to The new owner to be
# @param _tokenId The NFT to transfer
@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
  self._transferMechanism(_from, _to, _tokenId, msg.sender)

# @notice Transfers the ownership of an NFT from one address to another address
# @dev Throws unless `msg.sender` is the current owner, an authorized operator,
# or the approved address for this NFT. Throws if `_from` is not the current
# owner. Throws if `_to` is the ZERO_ADDRESS. Throws if `_tokenId` is not a valid
# NFT. When the transfer is complete, this function checks if `_to` is a smart
# contract(codesize > 0/is_contract member method). If so, it calls `onERC721Received` on `_to` and throws
# if the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
# @param _from The current owner of the NFT
# @param _to The new to be owner of the NFT
# @param _tokenId The NFT to transfer
# @param _data Additional data with no specified format, sent in call to `_to`
@external
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: Bytes[1024]=b""):
  self._transferMechanism(_from, _to, _tokenId, msg.sender)
  if _to.is_contract: # Check if `_to` is a contract address
    returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
    # Throws if `_to` is a contract address which does not implement 'onERC721Received'
    assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)

# @notice Set or reaffirm the approved address for an NFT
# @dev The zero address indicates there is no approved address
# @dev Throws unless `msg.sender` is the current NFT owner, or an
# authorized operator of the current owner
# @dev Throw if `_tokenId` is not a valid NFT
# @dev Throw id `_approved` is the current owner
# @param _approved The new approved NFT controller
# @param _tokenId The NFT to approve
@external
def approve(_approved: address, _tokenId: uint256):
  # Get owner
  owner: address = self.idToApprovals[_tokenId]
  # Check `_approved` is the current owner
  assert _approved != owner
  # Check `_tokenId` is valid
  assert owner != ZERO_ADDRESS
  # Check requirements
  senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
  senderIsOperator: bool = self.ownerAddressToOperator[owner][msg.sender]
  assert (senderIsOwner or senderIsOperator)
  # Set approval
  self.idToApprovals[_tokenId] = _approved
  log Approval(owner, _approved, _tokenId)

# @notice Enable or disable approval for a third party("operator") to
# manage all of `msg.sender`'s assets
# @dev Emit the ApprovalForAll event. The contract must allow multiple
# operators per owner
# @param _operator Address to add to the set of authorized operators
# @param _approved True if the operator is approved, false to revoke approval
@external
def setApprovalForAll(_operator: address, _approved: bool):
  assert _operator != ZERO_ADDRESS and _operator != msg.sender
  self.ownerAddressToOperator[msg.sender][_operator] = _approved
  log ApprovalForAll(msg.sender, _operator, _approved)

# MINT & BURN FUNCTIONS 

# @dev Mint token
# @dev Throws if `msg.sender` is not the minter
# @dev Throws if `_to` is ZERO_ADDRESS
# @dev Throws if `_tokenId` is owned by someone
# @return Boolean if mint was a success
@internal
def mint(_to: address, _tokenId: uint256) -> bool:
  # Throw if `_to` is ZERO_ADDRESS
  assert _to != ZERO_ADDRESS
  # Add NFT. Throw if `_tokenId` is owned by someone
  self._addToken(_to, _tokenId)
  # Log Transfer
  log Transfer(ZERO_ADDRESS, _to, _tokenId)
  return True

# @dev Burn token
# @dev Throw unless `msg.sender` is the current owner, an authorized operator,
# or the approved address for this NFT
# @dev Throws if `_tokenId` is not a valid NFT
# @param _tokenId Token to burn
@external
def burn(_tokenId: uint256):
  # Check `msg.sender` is the current owner, an authorized operator,
  # or the approved address for this NFT
  assert self._isApprovedOrOwner(msg.sender, _tokenId)
  owner: address = self.idToOwner[_tokenId]
  # Throw if `_tokenId` is not a valid NFT
  assert owner != ZERO_ADDRESS
  self._clearApproval(owner, _tokenId)
  self._removeToken(owner, _tokenId)
  # Log Transfer
  log Transfer(owner, ZERO_ADDRESS, _tokenId)

# @dev Tokenized farm lands
# @param _name Name of the farm
# @param _size Size of the land
# @param _longitude Location of the farm(lon)
# @param _latitude Location of the farm(lat)
# @param _imageHash IPFS image upload hash of the farm
# @param _tokenId Token ID to mint
# @param _soil Farm land soil type
# @dev Throw if `_tokenId` is already minted
@external
def tokenizeLand(_name: String[100], _size: String[20], _location: String[225], _imageHash: String[255], _soil: String[20], _tokenId: uint256):
  # Check token id is valid
  # Mint token
  self.mint(msg.sender, _tokenId)
  # Tokenize farm land
  self.tokenizedLands += 1
  _farm: Farm = Farm({
    tokenId: _tokenId,
    name: _name,
    size: _size,
    location: _location,
    imageHash: _imageHash,
    soil: _soil,
    season: 'Dormant',
    owner: msg.sender,
    userIndex: self.ownerNFTCount[msg.sender],
    platformIndex: self.tokenizedLands
  })
  self.tokenizedFarms[_tokenId] = _farm
  self.indexedTokenizedFarms[self.tokenizedLands] = _farm
  # Indexed
  (self.ownedNFT[msg.sender])[self.ownerNFTCount[msg.sender]] = _farm
  log Tokenize(msg.sender, _tokenId, _name) 

# @dev Query tokenized farm land
# @dev Throw if `_tokenId` is not valid
# @param _index Index of the farm
# @return Farm
@external
@view
def queryUserTokenizedFarm(_index: uint256) -> Farm:
  assert _index <= self.ownerNFTCount[msg.sender]
  return (self.ownedNFT[msg.sender])[_index]

# @dev Return tokenized farm
# @dev Throw if `_index` is > self.tokenizedLands
# @return Farm
@external
@view
def queryTokenizedFarm(_index: uint256) -> Farm:
  assert _index <= self.tokenizedLands
  return self.indexedTokenizedFarms[_index]

# @dev Get farm attached to the token
# @param _tokenId Token id
# Throw if `self.idToOwner[_tokenId] == ZERO_ADDRESS`
# @returns Farm
@external
@view
def getFarm(_tokenId: uint256) -> Farm:
  assert self.idToOwner[_tokenId] != ZERO_ADDRESS
  return self.tokenizedFarms[_tokenId]

# @dev Return total number of tokenized farms
# @return uint256
@external
@view
def totalTokenizedFarms() -> uint256:
  return self.tokenizedLands

# @dev Check if farm is tokenized
# @param _tokenId Token ID to verify
# @return bool
@external
@view
def exists(_tokenId: uint256) -> bool:
  if self.idToOwner[_tokenId] == ZERO_ADDRESS:
    return False
  else:
    return True

# @dev Update farm state
# @param _tokenId Token ID
@external
def transitionState(_tokenId: uint256, _state: String[20], _sender: address):
  assert self.idToOwner[_tokenId] != ZERO_ADDRESS # dev: Invalid address
  assert self.idToOwner[_tokenId] == _sender # dev: only owner can update state
  # Update platform tokenized farm
  self.tokenizedFarms[_tokenId].season = _state
  # Update user tokenized farm
  self.indexedTokenizedFarms[self.tokenizedFarms[_tokenId].platformIndex].season = _state
  # Update user owned NFT
  (self.ownedNFT[_sender])[self.tokenizedFarms[_tokenId].userIndex].season = _state

# @dev Get token state
# @param _tokenId Token ID
# @return String
@external
@view
def getTokenState(_tokenId: uint256) -> String[20]:
  assert self.idToOwner[_tokenId] != ZERO_ADDRESS
  return self.tokenizedFarms[_tokenId].season

