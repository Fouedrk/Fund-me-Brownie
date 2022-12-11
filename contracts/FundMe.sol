// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256; 

    mapping(address => uint256) public addressToAmount;
    address[] public funders; //Add the address of a funder in an array
    address owner; //Address of the owner of the contract
    AggregatorV3Interface public priceFeed;

    constructor(address price_Feed) public {
        priceFeed = AggregatorV3Interface(price_Feed);
        owner = msg.sender; //The deployer of the contract will be the owner.
    }

    // payable: Function to pay for things
    // Function to send money
    function fund() public payable {
        //Set a minimum value to send
        uint256 minUSD = 50 * 10**18; //50$ 
        // If the sended value is less than the minUSD stop excecution.
        require(getConversion(msg.value) >= minUSD, "You must spend more ETH!");
        addressToAmount[msg.sender] += msg.value; 
        funders.push(msg.sender); 
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // Get ETH price
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * (10 ^ 10));
    }

    //Convert whatever value they send
    function getConversion(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = ((ethPrice * ethAmount) / (10**18)); 
        return ethAmountInUSD;
    }

    function getEntranceFee() public view returns (uint256) {
        // min USD
        uint256 minUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minUSD * precision) / price) + 1;
    }
    //Modifier so that only the owner of the contract can withdraw money
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; 
    }

    //Withdraw all the money this contract holds from funding
    function withdraw() public payable onlyOwner {
        //transfer(): Send ETH from 1 address to another.
        msg.sender.transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmount[funder] = 0; //Empty the balance of each address
        }
        funders = new address[](0); 
    }
}
