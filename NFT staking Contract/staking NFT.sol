// SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;
interface IERC777 {

    function send(address recipient,uint256 amount,bytes calldata data) external;
    function burn(uint256 amount, bytes memory data) external ;
    function operatorSend(address sender,address recipient,uint256 amount,bytes calldata data,bytes calldata operatorData) external;
}

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


contract Staking     {
    

    IERC777 public Token;
    IERC721 public NFT;
    address public owner;
    uint256 public receiveIds;
    uint256 public rewardTokenPerDay = 20  ; 
    uint256 public rewardBurningPercentage = 3 ;

    constructor(IERC721 NFT_,IERC777 Token_) {
        NFT = NFT_;
        Token = Token_;
        owner = msg.sender;
    }
        

    struct userDetail {
        uint256 StakeTime;
        uint256 StakeAmount;
        uint256 Withdraw;
    }

    mapping(address => userDetail) public UserInfo;
    mapping(address => bool) public isStaked;
    
    modifier onlyOwner{
      require  (msg.sender == owner," You are not Owner!");
        _;
    }

    modifier onlyStaking{
        require( checkBool(msg.sender) == true ," Only Staking Allowed ");
        _;
    }

    function checkBool(address user) public view returns (bool){
       return isStaked[user];
    }


    // function stake(uint256 _tokenId) public {
    //     require(!isStaked[msg.sender],"Unstake First");
    //     UserInfo[msg.sender].StakeAmount += _tokenId ;
    //     UserInfo[msg.sender].StakeTime = block.timestamp ;
    //     isStaked[msg.sender]=true;
    //     NFT.safeTransferFrom(msg.sender,address(this),_tokenId);
    //     receiveIds += _tokenId;
    // }

    function stake1(uint256 _tokenId) public {
        require(!isStaked[msg.sender],"Unstake First");
        UserInfo[msg.sender].StakeAmount += _tokenId ;
        UserInfo[msg.sender].StakeTime = block.timestamp ;
        isStaked[msg.sender]=true;
        NFT.transferFrom(msg.sender,address(this),_tokenId);
        receiveIds += _tokenId;
    }
    
    function unStake() public {
        require(block.timestamp >= UserInfo[msg.sender].StakeTime + 60 seconds,"Lock for 1 minutes");
        UserInfo[msg.sender].StakeTime = 0;
        UserInfo[msg.sender].StakeAmount = 0;
        isStaked[msg.sender]=false;
    }

    function calculateReward(address _user) public view  returns(uint256) {
        uint256 Reward  ;
        uint256 totalTime = (block.timestamp - UserInfo[_user].StakeTime  ) / 1 seconds ;
        Reward = (((rewardTokenPerDay * 1 ether / 60 seconds )* totalTime) * UserInfo[_user].StakeAmount) / 1e18 ; 
        return Reward - UserInfo[_user].Withdraw;          
    } 

    function updateBurningPercentage(uint256 _percentage) public onlyOwner {
        rewardBurningPercentage = _percentage ; 
    }

    function getPercentage(uint256 _value) public view returns(uint256,uint256) {
       uint256 burnpercentage = (_value * (rewardBurningPercentage)) / (100);
       uint256 reward = _value - (burnpercentage);
       uint256 burnAmount;
       burnAmount = burnpercentage;
       return (reward,burnAmount);
    }
    
    function WithDraw() public onlyStaking{
        require(isStaked[msg.sender]," Plz Stake First");
        uint256 rewardX = calculateReward(msg.sender);
       (uint256 totalReward,uint256 burnTkn)= getPercentage(rewardX);
        Token.operatorSend(address(this),msg.sender,totalReward,"","");
        Token.burn(burnTkn,"");
        UserInfo[msg.sender].Withdraw += rewardX ;
    }
   
}