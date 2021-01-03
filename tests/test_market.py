import pytest
import brownie

token_id = 4863475

@pytest.fixture
def market_contract(FRMRegistry, Season, Market, accounts):
    farm_registry = FRMRegistry.deploy({'from': accounts[0]})
    farm_registry.tokenizeLand('Arunga Vineyard', '294.32ha', 'Lyaduywa, Kenya', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'loam soil', token_id, {'from': accounts[0]})
    season_contract = Season.deploy(farm_registry.address, {'from': accounts[0]})
    season_contract.openSeason(token_id)
    season_contract.confirmPreparations(token_id, 'Tomatoe', 'Organic Fertilizer', 'Cow Shed Manure', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    season_contract.confirmPlanting(token_id, 'F1', 'Kenya Seed Company', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', '1200kg', 'Jobe 1960 Organic Fertilizer', 'Kenya Seed Supplier', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    season_contract.confirmGrowth(token_id, 'Army worm', 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789', 'Infestor x32H', 'Aphids Supplier' , 'QmUfideC1r5JhMVwgd8vjC7DtVnXw3QGfCSQA7fUVHK789')
    season_contract.confirmHarvesting(token_id, "120 KG")
    yield Market.deploy(farm_registry.address, season_contract.address, {'from': accounts[0]})

def test_initial_state(market_contract):

    # Assertions
    assert market_contract.platformTransactions() == 0
    assert market_contract.farmTransactions(token_id) == 0
    assert market_contract.totalMarkets() == 0

def test_create_market(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")
    # Query market
    market = market_contract.getCurrentFarmMarket(token_id)

    # Assertions
    assert market_contract.totalMarkets() == 1
    assert market['price'] == _price
    assert market['remainingSupply'] == 3
    assert market_contract.isSeasonMarketed(token_id, 1) == True

def test_query_current_farm_market(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Query current farm market
    market = market_contract.getCurrentFarmMarket(token_id)

    # Assertions
    assert market['remainingSupply'] == 3

def test_invalid_market_create_with_existing_supply(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'tomatoe', _price, 3, "KG")

    # Error assertion
    with brownie.reverts('dev: exhaust previous market supply'):
        market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

def test_invalid_market_create_with_invalid_tokenized_farm(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')

    # Error assertion
    with brownie.reverts('dev: invalid tokenized farm'):
        market_contract.createMarket(3, 'Tomatoe', _price, 3, "KG")

def test_query_enlisted_markets(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Query markets
    markets = list()
    totalMarkets = market_contract.totalMarkets()
    for i in range(1, totalMarkets+1):
        market = market_contract.getCurrentFarmMarket(market_contract.getIndexedEnlistedMarket(i))
        markets.append(market)

    # Assertions
    assert markets[0]['price'] == _price

def test_invalid_booking_with_invalid_tokenized_farm(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: invalid token id'):
        market_contract.bookHarvest(3, 2, 1, {'from': accounts[1], 'value': _price * 2})

def test_invalid_booking_with_not_farm_owner(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: owner cannot book his/her harvest'):
        market_contract.bookHarvest(token_id, 2, 1, {'from': accounts[0], 'value': _price * 2})

def test_invalid_booking_with_insufficient_funds(market_contract, accounts, web3):
    _price = web3.toWei(0, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: booking funds cannot be 0'):
        market_contract.bookHarvest(token_id, 2, 1, {'from': accounts[1], 'value': _price * 2})

def test_invalid_booking_with_excess_booking_funds(market_contract, accounts, web3):
    _price = web3.toWei(2, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: insufficient booking funds'):
        market_contract.bookHarvest(token_id, 2, 1, {'from': accounts[1], 'value': _price * 1})

def test_invalid_booking_with_insufficient_booking_fee(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    with brownie.reverts('dev: insufficient booking funds'):
        market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': _price * 2})

def test_book_harvest(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

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
    assert bookings == 1
    assert market_bookings == 1
    assert market['bookers'] == 1
    assert market['remainingSupply'] == 1
    assert booking_list[0]['deposit'] == web3.toWei(2, 'ether')
    assert booking_list[0]['volume'] == 2
    assert market_booking_list[0]['booker'] == accounts[1]
    assert market_booking_list[0]['volume'] == 2
    assert market_booking_list[0]['deposit'] == web3.toWei(2, 'ether')

def test_query_previous_markets_for_farm(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Get previous markets
    previous_markets = list()
    total_previous_markets = market_contract.farmPrevMarkets(token_id)
    for i in range(1, total_previous_markets+1):
        previous_markets.append(market_contract.getFarmPrevMarket(token_id, i))

    # Assertions
    assert previous_markets[0]['originalSupply'] == 3
    assert previous_markets[0]['remainingSupply'] == 0
    assert previous_markets[0]['bookers'] == 1

def test_receive_confirmation_with_invalid_tokenized_farm(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Error assertion
    with brownie.reverts('dev: invalid token id'):
        market_contract.confirmReceivership(77777777, 3, 1, accounts[0], accounts[2], 'Rotten tomatoes', {'from': accounts[1], 'value': web3.toWei(0.003, 'ether')})

def test_receive_confirmation_with_invalid_booker(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Error assertion
    with brownie.reverts('dev: no bookings'):
        market_contract.confirmReceivership(token_id, 1, 1, accounts[0], accounts[2], 'Rotten tomatoes')

def test_receive_confirmation_with_invalid_booking_volume(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Error assertion
    with brownie.reverts('dev: volume out of range'):
        market_contract.confirmReceivership(token_id, 4, 1, accounts[0], accounts[2], 'Rotten tomatoes', {'from': accounts[1], 'value': web3.toWei(0.003, 'ether')})

def test_receive_confirmation_with_zero_booking_volume(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Error assertion
    with brownie.reverts('dev: volume cannot be 0'):
        market_contract.confirmReceivership(token_id, 0, 1, accounts[0], accounts[2], 'Rotten tomatoes', {'from': accounts[1], 'value': web3.toWei(0.003, 'ether')})

def test_receive_confirmation_with_insufficient_booking_fee(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Error assertion
    with brownie.reverts('dev: insufficient confirmation fee'):
        market_contract.confirmReceivership(token_id, 2, 1, accounts[0], accounts[2], 'Rotten tomatoes', {'from': accounts[1], 'value': web3.toWei(0.002, 'ether')})

def test_receive_confirmation(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")
    prev_balance = accounts[2].balance()
    prev_owner_balance = accounts[0].balance()

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Confirm receivership
    market_contract.confirmReceivership(token_id, 1, 1, accounts[0], accounts[2], 'Rotten tomatoes', {'from': accounts[1], 'value': web3.toWei(0.0037, 'ether')})

    # Assertions
    new_balance = prev_balance + web3.toWei(0.0037, 'ether')
    new_owner_balance = prev_owner_balance + (web3.toWei(1, 'ether') - web3.toWei(0.0037, 'ether'))
    assert new_owner_balance == accounts[0].balance()
    assert new_balance  == accounts[2].balance()
    assert market_contract.accountDeliverables(accounts[1]) == 1
    assert market_contract.farmDeliverables(token_id) == 1
    sealed_tx = booking_fee - web3.toWei(0.0037, 'ether')
    assert market_contract.platformTransactions() == sealed_tx

def test_get_review_for_invalid_tokenized_farm_market(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")
    prev_balance = accounts[2].balance()
    prev_owner_balance = accounts[0].balance()

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Confirm receivership
    market_contract.confirmReceivership(token_id, 1, 1, accounts[0], accounts[2], 'Rotten tomatoes', {'from': accounts[1], 'value': web3.toWei(0.0037, 'ether')})   

    # Error assertion
    with brownie.reverts('dev: invalid token id'):
        market_contract.marketReviewCount(4)

def test_get_market_review(market_contract, accounts, web3):
    _price = web3.toWei(1, 'ether')
    market_contract.createMarket(token_id, 'Tomatoe', _price, 3, "KG")
    prev_balance = accounts[2].balance()
    prev_owner_balance = accounts[0].balance()

    # Book harvest
    booking_fee = web3.toWei(1, 'ether')
    market_contract.bookHarvest(token_id, 3, 1, {'from': accounts[1], 'value': booking_fee * 3})

    # Confirm receivership
    market_contract.confirmReceivership(token_id, 1, 1, accounts[0], accounts[2], 'Rotten tomatoes', {'from': accounts[1], 'value': web3.toWei(0.0037, 'ether')})

    # Get reviews for this market
    reviews = market_contract.marketReviewCount(token_id)
    allReviews = list()
    for i in range(1, reviews+1):
        allReviews.append(market_contract.getReviewForMarket(token_id, i))
    # Assertions
    assert reviews == 1
    assert len(allReviews) == 1
    assert allReviews[0][1] == 'Rotten tomatoes'

