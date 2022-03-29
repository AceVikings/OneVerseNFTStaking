//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PriceSigner.sol";

contract Staking is Ownable,PriceSigner{

    IERC721 NFT;
    IERC20 Token;

    struct stakeInfo{
        address owner;
        uint stakeTime;
        uint position;
    }

    mapping(uint=>stakeInfo) public stakedTokens;
    mapping(address=>uint[]) userStaked;

    address designatedSigner = 0x08042c118719C9889A4aD70bc0D3644fBe288153;

    uint public Rate = 2;

    constructor(address _nft,address _token){
        NFT = IERC721(_nft);
        Token = IERC20(_token);
    }

    function stakeNFT(uint[] memory tokenIds) external {
        for(uint i=0;i<tokenIds.length;i++){
            require(NFT.ownerOf(tokenIds[i])==msg.sender,"Not owner");
            stakedTokens[tokenIds[i]] = stakeInfo(msg.sender,block.timestamp,userStaked[msg.sender].length);
            userStaked[msg.sender].push(tokenIds[i]);
            NFT.transferFrom(msg.sender,address(this),tokenIds[i]);
        }
    }

    function claimRewards(uint[] memory tokenIds,Price memory price) public{
        require(getSigner(price)==designatedSigner,"Invalid signer");
        require(block.timestamp - price.time < 5 minutes,"price expired");
        uint amount;
        for(uint i=0;i<tokenIds.length;i++){
            stakeInfo storage currInfo = stakedTokens[tokenIds[i]];
            require(currInfo.owner==msg.sender,"Not owner");
            amount += (block.timestamp - currInfo.stakeTime)*price.price*Rate*10**10/1 days;
            currInfo.stakeTime = block.timestamp;            
        }
        Token.transfer(msg.sender, amount);
    }

    function getReward(uint tokenId) public view returns(uint){
        if(stakedTokens[tokenId].stakeTime == 0){
            return 0;
        }
        return (block.timestamp - stakedTokens[tokenId].stakeTime)*Rate*10**18/1 days;
    }

    function unstakeTokens(uint[] memory tokenIds,Price memory price) external{
        claimRewards(tokenIds,price);
        for(uint i=0;i<tokenIds.length;i++){
            stakeInfo storage currInfo = stakedTokens[tokenIds[i]];
            require(currInfo.owner==msg.sender,"Not owner");
            NFT.transferFrom(address(this),msg.sender,tokenIds[i]);
            popToken(tokenIds[i]);
            delete stakedTokens[tokenIds[i]];
        }
    }

    function popToken(uint tokenId) private {
        uint lastToken = userStaked[msg.sender][userStaked[msg.sender].length-1];
        uint currPosition = stakedTokens[tokenId].position;
        userStaked[msg.sender][currPosition] = lastToken;
        stakedTokens[lastToken].position = currPosition;
        userStaked[msg.sender].pop();
    }

    function emergencyUnstake(uint[] memory tokenIds) external{
        for(uint i=0;i<tokenIds.length;i++){
            stakeInfo storage currInfo = stakedTokens[tokenIds[i]];
            require(currInfo.owner==msg.sender || owner() == msg.sender,"Not owner");
            NFT.transferFrom(address(this),currInfo.owner,tokenIds[i]);
            popToken(tokenIds[i]);
            delete stakedTokens[tokenIds[i]];
        }
    }


    function getUserStaked(address _user) external view returns(uint[] memory){
        return userStaked[_user];
    }

    function retrieveRewardToken() external onlyOwner{
        Token.transfer(msg.sender,Token.balanceOf(address(this)));
    }

    function serRate(uint _rate) external onlyOwner{
        Rate = _rate;
    }

    function setNFT(address _nft) external onlyOwner{
        NFT = IERC721(_nft);
    }

    function setToken(address _token) external onlyOwner{
        Token = IERC20(_token);
    }

    function setSigner(address _signer) external onlyOwner{
        designatedSigner = _signer;
    }

}