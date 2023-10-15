//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HorseGame is ERC1155, Ownable
{

    uint public numOfHorses;
    uint public maxNumOfHorses = 10000;

    string private _uri = "";

    uint public nftPrice = 0.01 ether;
    uint public tokenPrice = 0.0001 ether;

    address marketplaceAddress;

    uint public constant COIN = 1;

    uint public constant SPEED_UTILS = 10;
    uint public constant DURABILITY_UTILS = 20;
    uint public constant STABILITY_UTILS = 30;

    uint public constant HORSE_INIT_ID = 200000000;

    mapping(uint => horse) public horses;

    struct horse
    {
        address owner;

        uint speed;
        uint durability;
        uint stability;

        uint breeding_count;
        uint race_count;
        mapping(uint => uint) race_results;
    }


    address public admin;
    uint public contractBalance;
    uint public racesBalance;
    address treasury;
    uint treasuryBalance;
    uint public unit = 20;
    uint public raceId;
    uint constant NUMBER_OF_RACERS = 8;


    // race data tracking
    struct Race {
        uint class;
        uint balance;
        uint numOfRacers;
        bool finished;
        address[] racerAddresses;
        uint[] racerHorses;
        uint[] raceResult;
    }

    mapping(uint => Race) public races;

    event StartRace(uint indexed _raceId);

    event EndRace(uint indexed _raceId);


    /**
     * @notice Constructor
     * @dev See {@openzeppelin/ERC1155-constructor}.
     */
    constructor() ERC1155(_uri) {
        admin = msg.sender;
        treasury = msg.sender;
    }


    /**
     * @notice mints the requested amount of in-game Coins to the sender
     * @param _amount : amount of in-game Coins to be minted
     */
    function mintCoin(uint _amount) public payable
    {
        require(msg.value >= tokenPrice * _amount, "mintCoin: Not enough MATIC");
        _mint(msg.sender, COIN, _amount, "");
    }

    /**
     * @notice mints one horse for the sender
     * param _name : name of the horse
     * param _age : age of the horse
     */
    function mintHorse(/*string memory _name, uint _age*/) public payable returns(uint)
    {
        return mintHorse(msg.sender);
    }

    /**
     * @notice mints one horse for the given address
     * param _name : name of the horse
     * param _age : age of the horse
     */
    function mintHorse(address _minter) public payable returns(uint)
    {
        if (msg.sender != owner()) {
            require(msg.value >= nftPrice, "mintHorse: Not enough MATIC");
        }
        require(numOfHorses < maxNumOfHorses, "mintHorse: exceeds mint limit");

        uint horseId = HORSE_INIT_ID + (++numOfHorses);
        _mint(_minter, horseId, 1, "");

        horses[horseId].owner = _minter;

        horses[horseId].speed = 10;
        horses[horseId].durability = 10;
        horses[horseId].stability = 10;

        return horseId;
    }

    /**
     * @notice mints Utility NFTs
     * @param _type : the type of the utility NFT (Speed: 10, Durability: 20, Stability: 30)
     * @param _quality : the quality of the utility NFT (Low quality: 1, High quality: 2)
     * @param _amount : the amount of the utility NFTs that will be minted
     */
    function mintUtil(uint _type, uint _quality, uint _amount) public
    {
        require(_type == SPEED_UTILS || _type == DURABILITY_UTILS || _type == STABILITY_UTILS, "mintUtil: type mismatch");
        require(_quality == 1 || _quality == 2, "mintUtil: _quality mismatch");

        uint mintPrice = 10 * (_quality+1) * _amount;
        require(mintPrice <= balanceOf(msg.sender, COIN), "mintUtil: Not enough NFX");

        _burn(msg.sender, COIN, mintPrice);
        _mint(msg.sender, _type+_quality, _amount, "");
    }

    /**
     * @notice [Batched] version of mintUtil
     * @param _types : types of the utility NFTs (Speed: 10, Durability: 20, Stability: 30)
     * @param _qualities : quality of the utility NFTs (Low quality: 1, High quality: 2)
     * @param _amounts : amounts of the utility NFTs that will be minted
     */
    function mintUtilBatch(uint[] memory _types, uint[] memory _qualities, uint[] memory _amounts) public
    {
        require(_types.length == _qualities.length && _types.length == _amounts.length, "mintUtilBatch: input lengths mismatch");

        uint mintPrice;
        uint[] memory ids = new uint[](_types.length);
        for (uint i = 0; i < _types.length; i++) {
            require(_types[i] == SPEED_UTILS || _types[i] == DURABILITY_UTILS || _types[i] == STABILITY_UTILS, "mintUtilBatch: type mismatch");
            require(_qualities[i] == 1 || _qualities[i] == 2, "mintUtilBatch: _qualities mismatch");
            mintPrice = 10 * (_qualities[i]+1) * _amounts[i];
            ids[i] = _types[i] + _qualities[i];
        }

        require(mintPrice <= balanceOf(msg.sender, COIN), "mintUtilBatch: Not enough NFX");

        _burn(msg.sender, COIN, mintPrice);
        _mintBatch(msg.sender, ids, _amounts, "");
    }

    /**
     * @notice upgrade the requested stat of the given horse
     * @param _horseId: ID of the horse
     * @param _stat: ID of the stat that will be upgraded: "10" for Speed, "20" for Durability, "30" for Stability
     */
    function upgradeHorse(uint _horseId, uint _stat) public
    {
        require(_horseId > HORSE_INIT_ID && _horseId <= HORSE_INIT_ID + numOfHorses, "upgradeHorse: _horseId mismatch");
        require(_stat == SPEED_UTILS || _stat == DURABILITY_UTILS || _stat == STABILITY_UTILS, "upgradeHorse: _stat mismatch");

        address horseOwner = horses[_horseId].owner;
        require(horseOwner == msg.sender, "upgradeHorse: not owner");
        
        uint stat;
        if(_stat == SPEED_UTILS) stat = horses[_horseId].speed;
        else if(_stat == DURABILITY_UTILS) stat = horses[_horseId].durability;
        else if(_stat == STABILITY_UTILS) stat = horses[_horseId].stability;

        require(stat < 100, "upgradeHorse: already max");

        uint[] memory tokenIds = new uint[](2);
        uint[] memory amounts = new uint[](2);
        tokenIds[0] = _stat+1;
        tokenIds[1] = _stat+2;

        if (stat/10 == 1) {
            require(balanceOf(horseOwner, _stat+1) >= 2 && balanceOf(horseOwner, _stat+2) >= 1, "upgradeHorse: low resources");
            amounts[0] = 2;
            amounts[1] = 1;
            _burnBatch(horseOwner, tokenIds, amounts);
        } else if (stat/10 == 2) {
            require(balanceOf(horseOwner, _stat+1) >= 3 && balanceOf(horseOwner, _stat+2) >= 1, "upgradeHorse: low resources");
            amounts[0] = 3;
            amounts[1] = 1;
            _burnBatch(horseOwner, tokenIds, amounts);
        } else if (stat/10 == 3) {
            require(balanceOf(horseOwner, _stat+1) >= 3 && balanceOf(horseOwner, _stat+2) >= 2, "upgradeHorse: low resources");
            amounts[0] = 3;
            amounts[1] = 2;
            _burnBatch(horseOwner, tokenIds, amounts);
        } else {
            require(balanceOf(horseOwner, _stat+1) >= stat/10 && balanceOf(horseOwner, _stat+2) >= (stat/10) - 2, "upgradeHorse: low resources");
            amounts[0] = stat/10;
            amounts[1] = (stat/10)-2;
            _burnBatch(horseOwner, tokenIds, amounts);
        }

        if(_stat == SPEED_UTILS) horses[_horseId].speed = stat+1;
        else if(_stat == DURABILITY_UTILS) horses[_horseId].durability = stat+1;
        else if(_stat == STABILITY_UTILS) horses[_horseId].stability = stat+1;

    }


    /**
     * @notice returns the stats of the horse
     * @param _horseId : ID of the horse
     * @param _statId : 0 for "level", 1 for "speed", 2 for "durability", 3 for "stability"
     */
    function horseStats(uint _horseId, uint _statId) public view returns(uint)
    {
        require(_horseId > HORSE_INIT_ID && _horseId <= HORSE_INIT_ID + numOfHorses, "_resultTheRace: _horseId mismatch");

        if (_statId == 0) return (horses[_horseId].speed + horses[_horseId].durability + horses[_horseId].stability) / 3;
        else if (_statId == 1) return horses[_horseId].speed;
        else if (_statId == 2) return horses[_horseId].durability;
        else if (_statId == 3) return horses[_horseId].stability;
        else return 0;
    }

    /**
     * @notice sets the NTF minting price to a new value
     * @param _newPrice : new price
     * @param _type : 0 for Horse, 1 for token
     */
    function setPrice(uint _newPrice, uint _type) external onlyOwner 
    {
        require (_type == 0 || _type == 1, "setPrice: type mismatch");
        if (_type == 0) nftPrice = _newPrice;
        else tokenPrice = _newPrice;
    }

    /**
     * @notice Withdraws all  Matic Tokens from the contract, only callable by the owner
     */
    function withdrawAll() external onlyOwner
    {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Changes maximum number of Horses that can be minted
     * @param _newLimit : new maximum number of horse NFTs
    */
    function changeMaxHorses(uint _newLimit) external onlyOwner
    {
        require(maxNumOfHorses < _newLimit, "changeMaxHorses: Given limit is less than current maximum number of horses!");
        maxNumOfHorses = _newLimit;
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public override {
        require(id > HORSE_INIT_ID && id <= HORSE_INIT_ID + numOfHorses, "safeTransferFrom: NOT horse");

        require(horses[id].owner == from);
        ERC1155.safeTransferFrom(from, to, id, amount, data);
        horses[id].owner = to;
    }

    /**
     * @notice returns the number of all horses and their IDs for the given address as an array
     * @param _racer : address of the racer
     */
    function checkHorseBalance(address _racer) public view returns(uint[] memory) {
        uint totalHorses;
        for (uint id = HORSE_INIT_ID + 1; id <= HORSE_INIT_ID + numOfHorses; id++) {
            if(horses[id].owner == _racer) totalHorses++;
        }

        uint[] memory returnHorses = new uint[](totalHorses+1);
        returnHorses[0] = totalHorses;
        uint i;
        for (uint id = HORSE_INIT_ID + 1; id <= HORSE_INIT_ID + numOfHorses; id++) {
            if(horses[id].owner == _racer) {
                returnHorses[++i] = id;
            }
        }
        return returnHorses;
    }
    /**
     * @notice set URI to a new value
     * @param _newURI : new URI for NFTs
     */
    function setURI(string memory _newURI) external onlyOwner() {
        _setURI(_newURI);
    }

    /**
     * @notice update the results data of a given horse
     * @param _horseId: ID of the horse
     * @param _raceId: ID of the race
     * @param _place: the place of the horse in the race
     */
    function _resultTheRace(
        uint _horseId,
        uint _raceId,
        uint _place
        ) private {
        require(_horseId > HORSE_INIT_ID && _horseId <= HORSE_INIT_ID + numOfHorses, "_resultTheRace: _horseId mismatch");

        horses[_horseId].race_count++;
        horses[_horseId].race_results[_raceId] = _place;
    }

    /**
     * @notice calculates the contract ID of the horse
     * @param _horseId : ID of the horse
     */
    function _calculateHorseId(uint _horseId) private pure returns(uint)
    {
        return _horseId + HORSE_INIT_ID;
    }



    function startRace(
        uint _raceId,
        address[] memory _racers,
        uint[] memory _horses,
        uint _class
    ) external returns (uint) {

        require(_racers.length <= NUMBER_OF_RACERS, "Game: number of racers cannot exceed maximum allowed");
        require(_racers.length == _horses.length, "Game: number of racers and horses have to be equal");

        races[_raceId].racerAddresses = _racers;

        uint entryPrice = _class * unit;// <-- Change the entry price of the race

        for (uint8 i=0; i < _racers.length; i++) {
            require(balanceOf(_racers[i], COIN) >= entryPrice, "startRace: Each racer must have at least entry price in their balance!");
        }


        uint tempBalance = 0;

        races[_raceId].numOfRacers = _racers.length;

        for (uint8 i=0; i < races[_raceId].numOfRacers; i++) {
            _burn(_racers[i], COIN, entryPrice);
            tempBalance += entryPrice;
        }

        races[_raceId].balance = tempBalance;
        races[_raceId].finished = false;
        races[_raceId].class = _class;

        racesBalance += tempBalance;

        emit StartRace(_raceId);

        return _raceId;
    }

    function endRace(
        uint _raceId,
        address[] memory _racers,
        uint[] memory _horses,
        uint[] memory _rankings
    ) external returns (bool) {

        require(!races[_raceId].finished, "endRace: This race is already finished!");
        races[_raceId].finished = true;

        require(races[_raceId].numOfRacers == _racers.length && _racers.length == _horses.length && _racers.length == _rankings.length, 
            "endRace: input length mismatch");

        for (uint8 i=0; i < races[_raceId].numOfRacers; i++) {
            require(races[_raceId].racerAddresses[i] == _racers[i], "endRace: list of racers mismatch");
        }
        races[_raceId].raceResult = _rankings;


        uint initBalance = races[_raceId].balance;

        for (uint8 i=0; i < races[_raceId].numOfRacers; i++) {
            // NOTE: Without the given percentages, if-else statements needed

            _resultTheRace(_horses[i], _raceId, _rankings[i]);

            if (races[_raceId].raceResult[i] == 1) {
                races[_raceId].balance -= (initBalance * 45 / 100);
                _mint(_racers[i], COIN, (initBalance * 45 / 100), "");  // <-- 1.  %45
            } else if (races[_raceId].raceResult[i] == 2) {
                races[_raceId].balance -= (initBalance * 18 / 100);
                _mint(_racers[i], COIN, (initBalance * 18 / 100), "");  // <-- 1.  %18
            } else if (races[_raceId].raceResult[i] == 3) {
                races[_raceId].balance -= (initBalance * 13 / 100);
                _mint(_racers[i], COIN, (initBalance * 13 / 100), "");  // <-- 1.  %13
            } else if (races[_raceId].raceResult[i] == 4) {
                races[_raceId].balance -= (initBalance * 9 / 100);
                _mint(_racers[i], COIN, (initBalance * 9 / 100), "");  // <-- 1.  %9
            } else if (races[_raceId].raceResult[i] == 5) {
                races[_raceId].balance -= (initBalance * 5 / 100);
                _mint(_racers[i], COIN, (initBalance * 5 / 100), "");  // <-- 1.  %5
            }
        }

        treasuryBalance += races[_raceId].balance;

        races[_raceId].balance = 0;

        racesBalance -= initBalance;

        emit EndRace(_raceId);

        return true;
    }


    function changeTreasury(address _newTreasury) external onlyOwner {
        treasury = _newTreasury;
    }
}