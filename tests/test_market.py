import pytest
import brownie

token_id = 4863475

@pytest.fixture
def market_contract(FRMRegistry, Season, Market, accounts, web3):
    farm_registry = FRMRegistry.deploy({'from': accounts[0]})
    farm_registry.tokenizeLand('Arunga Vineyard', '294.32ha', '36.389223', '-1.282883', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    season_contract = Season.deploy(farm_registry.address, {'from': accounts[0]})
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure Supplier')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier')
    season_contract.confirmGrowth(token_id, 'Army worm', 'Infestor x32H', 'Aphids Supplier')
    _price = web3.toWei(1, 'ether')
    season_contract.confirmHarvesting(token_id, 5, 'kg', _price, 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    yield Market.deploy(farm_registry.address, season_contract.address, {'from': accounts[0]})

def test_initial_state(market_contract):

    # Assertions
    assert market_contract.platformTransactions() == 0
    assert market_contract.farmTransactions(token_id) == 0
    assert market_contract.totalMarkets() == 0

def test_create_market(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")
    # Query market
    market = market_contract.getEnlistedMarket(1)

    # Assertions
    assert market_contract.totalMarkets() == 1
    assert market['price'] == _price
    assert market['remainingSupply'] == 3

def test_query_current_farm_market(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Query current farm market
    market = market_contract.getCurrentFarmMarket(token_id)

    # Assertions
    assert market['remainingSupply'] == 3

def test_invalid_market_create_with_existing_supply(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Error assertion
    with brownie.reverts('dev: exhaust previous market supply'):
        market_contract.createMarket(token_id, _price, 4, "KG")

def test_invalid_market_create_with_invalid_tokenized_farm(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')

    # Error assertion
    with brownie.reverts('dev: invalid tokenized farm'):
        market_contract.createMarket(3, _price, 3, "KG")

def test_query_enlisted_markets(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Query markets
    markets = list()
    totalMarkets = market_contract.totalMarkets()
    for i in range(1, totalMarkets+1):
        market = market_contract.getEnlistedMarket(i)
        markets.append(market)

    # Assertions
    assert markets[0]['price'] == _price

def test_invalid_booking_with_invalid_tokenized_farm(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: invalid token id'):
        market_contract.bookHarvest(3, 2, 1, {'from': accounts[1], 'value': _price * 2})

def test_invalid_booking_with_not_farm_owner(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: owner cannot book his/her harvest'):
        market_contract.bookHarvest(token_id, 2, 1, {'from': accounts[0], 'value': _price * 2})

def test_invalid_booking_with_insufficient_funds(market_contract, accounts, web3):
    _price = web3.toWei(0, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: booking funds cannot be 0'):
        market_contract.bookHarvest(token_id, 2, 1, {'from': accounts[1], 'value': _price * 2})

def test_invalid_booking_with_excess_booking_funds(market_contract, accounts, web3):
    _price = web3.toWei(2, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: insufficient booking funds'):
        market_contract.bookHarvest(token_id, 2, 1, {'from': accounts[1], 'value': _price * 1})

def test_invalid_booking_with_insufficient_booking_fee(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: insufficient booking funds'):
        market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': _price * 2})

def test_book_harvest(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, _price, 3, "KG")

    # Book harvest
    _bookingFee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 1, 1, {'from': accounts[1], 'value': _bookingFee * 1})
    market_contract.bookHarvest(token_id, 1, 1, {'from': accounts[1], 'value': _bookingFee * 1})
    market = market_contract.getCurrentFarmMarket(token_id)

    # Get booker bookings
    bookings = market_contract.totalBookerBooking(accounts[1])
    booking_list = list()
    for i in range(1, bookings + 1):
        season_booked = market_contract.getSeasonBooked(i, accounts[1])
        booking_list.append(market_contract.getBookerBooking(season_booked, accounts[1]))

    # Get market bookings
    market_booking_list = list()
    market_bookings = market_contract.totalMarketBookers(token_id)
    for i in range(1, market_bookings+1):
        market_booking_list.append(market_contract.getMarketBooking(token_id, i))

    # Assertions
    assert market['bookers'] == 1
    assert market['remainingSupply'] == 1
    assert booking_list[0]['deposit'] == web3.toWei(2, 'ether')
    assert booking_list[0]['volume'] == 2
    assert market_booking_list[0]['booker'] == accounts[1]
    assert market_booking_list[0]['volume'] == 2
    assert market_booking_list[0]['deposit'] == web3.toWei(2, 'ether')


