// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
//import "remix_tests.sol"; // this import is automatically injected by Remix.
import "../contracts/TheGame.sol";

contract TheGameTest {
   
    TheGame game;

    function beforeAll () public {
        now = block.timestamp;
        oneMinute = 60;
        game = new TheGame(not+oneDay, now + (oneMinute*2), now + (oneMinute*3));
    }
    
    function checkWinningProposal () public {
        now = block.timestamp;
        game = new TheGame(now, now + 1000, now + 2000);
        Assert.equal(game.getState(), GameState.CREATED, "Initial state of the contract should be GameState.CREATED");
    }
}
