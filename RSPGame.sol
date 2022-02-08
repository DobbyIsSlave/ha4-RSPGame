//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    
    
    
    constructor () payable {}
    
    /*
    event GameCreated(address originator, uint256 originator_bet);
    event GameJoined(address originator, address taker, uint256 originator_bet, uint256 taker_bet);
    event OriginatorWin(address originator, address taker, uint256 betAmount);
    event TakerWin(address originator, address taker, uint256 betAmount);
   */
   
    enum Hand {
        rock, scissors, paper
    }
    
    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }
    
    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }
    
    // player structure
    struct Player {
        bytes32 hand;
        address payable addr;
        PlayerStatus playerStatus;
        uint256 playerBetAmount;
    }
    
    struct Game {
        uint256 betAmount;
        GameStatus gameStatus;
        Player originator;
        Player taker;
    }
    
    
    mapping(uint => Game) rooms;
    uint roomLen = 0;

    function RSPHashing (Hand hand, uint roomNum) private returns (bytes32) {
        return keccak256(abi.encodePacked(uint8(hand) + uint8(roomNum)));
    }
    
    modifier isValidHand (bytes32 _hand, uint roomNum) {
        require((_hand  == RSPHashing(Hand.rock, roomNum)) || (_hand  == RSPHashing(Hand.scissors, roomNum)) || (_hand == RSPHashing(Hand.paper, roomNum)));
        _;
    }
    
    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }
    
    function createRoom (bytes32 _hand) public payable isValidHand(_hand, roomLen) returns (uint roomNum) {
        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({ // will change
                hand: RSPHashing(Hand.rock, roomLen),
                addr: payable(msg.sender),  
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen;
        roomLen = roomLen+1;
        
        
       // Emit gameCreated(msg.sender, msg.value);
    }
    
    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand(RSPHashing(_hand, roomNum), roomNum) {
       // Emit gameJoined(game.originator.addr, msg.sender, game.betAmount, msg.value);
        
        rooms[roomNum].taker = Player({
            hand: RSPHashing(_hand, roomNum),
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        compareHands(roomNum);
    }
    
    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
         rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
    
    function compareHands(uint roomNum) private{
        uint8 originator;
        uint8 taker;
        if (RSPHashing(Hand.rock, roomNum) == rooms[roomNum].originator.hand) {
            originator = 0;
        } else if (RSPHashing(Hand.scissors, roomNum) == rooms[roomNum].originator.hand) {
            originator = 1;
        } else if (RSPHashing(Hand.paper, roomNum) == rooms[roomNum].originator.hand) {
            originator = 2;
        }

        if (RSPHashing(Hand.rock, roomNum) == rooms[roomNum].taker.hand) {
            taker = 0;
        } else if (RSPHashing(Hand.scissors, roomNum) == rooms[roomNum].taker.hand) {
            taker = 1;
        } else if (RSPHashing(Hand.paper, roomNum) == rooms[roomNum].taker.hand) {
            taker = 2;
        }
        
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        
        if (taker == originator){ //draw
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
            
        }
        else if ((originator + 1) % 3 == taker) { // originator wins
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if ((taker + 1) % 3 == originator){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
       
    }
}
