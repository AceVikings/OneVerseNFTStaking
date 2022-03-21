//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable{

    IERC721 NFT;
    IERC20 Token;

    struct stakeInfo{
        address owner;
        uint stakeTime;
        uint position;
    }

    mapping(uint=>stakeInfo) public stakedTokens;
    mapping(address=>uint[]) userStaked;

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

    function claimRewards(uint[] memory tokenIds) public{
        uint amount;
        for(uint i=0;i<tokenIds.length;i++){
            stakeInfo storage currInfo = stakedTokens[tokenIds[i]];
            require(currInfo.owner==msg.sender,"Not owner");
            amount += (block.timestamp - currInfo.stakeTime)*2/1 days;
            currInfo.stakeTime = block.timestamp;            
        }
        Token.transfer(msg.sender, amount);
    }

    function unstakeTokens(uint[] memory tokenIds) external{
        claimRewards(tokenIds);
        for(uint i=0;i<tokenIds.length;i++){
            stakeInfo storage currInfo = stakedTokens[tokenIds[i]];
            require(currInfo.owner==msg.sender,"Not owner");
            NFT.transferFrom(address(this),msg.sender,tokenIds[i]);
            popToken(tokenIds[i]);
        }
    }

    function popToken(uint tokenId) private {
        uint lastToken = userStaked[msg.sender][userStaked[msg.sender].length-1];
        uint currPosition = stakedTokens[tokenId].position;
        userStaked[msg.sender][currPosition] = lastToken;
        stakedTokens[lastToken].position = currPosition;
        userStaked[msg.sender].pop();
    }

    function setNFT(address _nft) external onlyOwner{
        NFT = IERC721(_nft);
    }

    function setToken(address _token) external onlyOwner{
        Token = IERC20(_token);
    }


}