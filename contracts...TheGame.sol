// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Owner.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

enum BetOpion {A, B}

struct Bet {
    address player;
    uint256 oddsA; // 1/odds
    uint256 oddsB; // 1/odds
    BetOpion betTakenFor;
    uint256 amount; //in ETH
}

enum GameState {CREATED, OPEN, BETS_CLOSED, FINISHED}


contract TheGame is Owner,  ChainlinkClient{
    using Chainlink for Chainlink.Request;

    event BetTaken(address indexed betTaker, uint256 indexed amount, BetOpion indexed option); 

    uint256 creationTime;
    uint256 startTime;
    uint256 betsEndTime;
    uint256 closeTime;

    //maybe it's also worth to remember timestamps of updates
    uint256 currentOddsA;
    uint256 currentOddsB;

    BetOpion winner;

    Bet[] bets; //maybe it's worth to set a limit for the bets amount

    constructor(uint256 _startTime, uint256 _betsEndTime, uint256 _closeTime) Owner() {
        creationTime = block.timestamp;
        // require(creationTime < _startTime, "Bet have to begin in the future");
        // require(_startTime < _betsEndTime, "Bets close time have to be after start time");
        // require(_betsEndTime < _closeTime, "Game close time have to be after bets close time");
        startTime = _startTime;
        betsEndTime = _betsEndTime;
        closeTime = _closeTime;
    }

    function getStartTime() public view returns(uint256) {
         return startTime;
    }

    function getBetsEndTime() public view returns(uint256) {
         return betsEndTime;
    }

    function getCloseTime() public view returns(uint256) {
         return closeTime;
    }

    function getState() public view returns(GameState) {
        uint256 ts = block.timestamp;
        if (ts < startTime)
            return GameState.CREATED;
        else if (startTime <= ts && ts < betsEndTime)
            return GameState.OPEN;
        else if (betsEndTime <= ts && ts < closeTime)
            return GameState.BETS_CLOSED;
        else //if (closeTime <= ts)
            return GameState.FINISHED;
    }

    //==================================================================

    function updateOddsA(uint256 odds) public isOwner returns(uint256) {
        require(getState() != GameState.FINISHED, "Odds can be changed only during the game");
        currentOddsA = odds;
        return currentOddsA;
    }
    
    function updateOddsB(uint256 odds) public isOwner returns(uint256) {
        require(getState() != GameState.FINISHED, "Odds can be changed only during the game");
        currentOddsB = odds;
        return currentOddsB;
    }

    //==================================================================
    function takeABet(BetOpion option) public payable returns(uint256){
        //add check of msg.value - amount of wei
        Bet memory bet = Bet(msg.sender, currentOddsA, currentOddsB, option, msg.value);
        bets.push(bet);
        emit BetTaken(bet.player, bet.amount, bet.betTakenFor);
        return bets.length;
    }

    //==================================================================
    function setAGameWinner(BetOpion option) public isOwner returns(BetOpion){
        //question is when to execute this function
        require (getState() == GameState.FINISHED, "To announce the winner the game have to be finished");
        winner = option;
        return winner;
    }

    //==================================================================
    function callREST() private isOwner returns(bytes32 requestId) {
        //Test function that depends on the picked Eth net. 
        //Use chainlink provided contracts as an oracle: https://docs.chain.link/docs/make-a-http-get-request/
        //For Rinkeby address is ????

        setPublicChainlinkToken(); 

        address oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8; //It's in KOVAN
        setChainlinkOracle(oracle);

        bytes32 jobId = "d5270d1c311941d0b08bead21fea7747";
        uint256 fee = 0.1 * 10 ** 18; // (Varies by network and job)
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        request.add("get", "https://https://finni.ogicom.pl/kext.php");
        //it will return static {"oddsA":5,"oddsB":1.25}
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        //TODO
    }
    // TODO: think about bellow:
    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}