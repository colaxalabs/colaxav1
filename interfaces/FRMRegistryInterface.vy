# Events

event Transfer:
    _from: address
    _to: address
    _tokenId: uint256
event Approval:
    _owner: address
    _approved: address
    _tokenId: uint256
event ApprovalForAll:
    _owner: address
    _operator: address
    _approved: bool
event Tokenize:
    _owner: address
    _tokenId: uint256
    _name: String[100]

# Functions

@view
@external
def name() -> String[4]:
    pass

@view
@external
def symbol() -> String[3]:
    pass

@view
@external
def baseURI() -> String[255]:
    pass

@view
@external
def totalSupply() -> uint256:
    pass

@view
@external
def totalTokenizedLands() -> uint256:
    pass

@view
@external
def supportsInterface(_interfaceId: bytes32) -> bool:
    pass

@view
@external
def balanceOf(_owner: address) -> uint256:
    pass

@view
@external
def ownerOf(_tokenId: uint256) -> address:
    pass

@view
@external
def getApproved(_tokenId: uint256) -> address:
    pass

@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    pass

@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    pass

@external
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256):
    pass

@external
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: Bytes[1024]):
    pass

@external
def approve(_approved: address, _tokenId: uint256):
    pass

@external
def setApprovalForAll(_operator: address, _approved: bool):
    pass

@external
def burn(_tokenId: uint256):
    pass

@external
def tokenizeLand(_name: String[100], _size: String[20], _longitude: decimal, _latitude: decimal, _imageHash: String[255], _soil: String[20], _tokenId: uint256):
    pass

@view
@external
def totalTokenizedFarms() -> uint256:
    pass

@view
@external
def exists(_tokenId: uint256) -> bool:
  pass

@external
def transitionState(_tokenId: uint256, _state: String[20], _sender: address):
    pass

@view
@external
def getTokenState(_tokenId: uint256) -> String[20]:
    pass

