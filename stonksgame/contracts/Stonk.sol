// SPDX-License-Identifier: MIT LICENSE
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Invitation.sol";

contract Stonk is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.002 ether;
  uint256 public maxSupply = 50000;
  uint256 public maxMintAmount = 2;
  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri;
  bool public presale = true;
  Invitation invitation;
  uint256 public stonkSupply = 0;
  

  IMarket public market;
 

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _invitation
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    invitation = Invitation(_invitation);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  function invitationCount() public view returns (uint256){

      return invitation.balanceOf(msg.sender);

  }

  // public
  //add dynamic minting
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(!presale || invitation.balanceOf(msg.sender)>=1, "Presale active: you don't have an invite :(");

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }    

    for (uint256 i = 1; i <= _mintAmount; i++) {

        _safeMint(msg.sender, supply + i);
        minted[seed] = 1;
    }
  }

  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the market's approval so that users don't have to waste gas approving
        if (_msgSender() != address(market)) {
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        }
        _transfer(from, to, tokenId);
    }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function setMarket(address _market) external onlyOwner {
        market = IMarket(_market);
    }
  
  function isStonk(uint256 tokenId) public view returns (bool){
    if (tokenId >= 45000){
      return false;
    } else {
      return true;
    }
  }

  function generateSeed(uint256 number, uint256 chance) public view returns (uint256){
    
    uint256 seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, number)));
    
    return (seed & 0xFFFF) % chance;
  }

  function selectReceipient() public view returns (address){
      uint256 seed = generateSeed(paintingSupply+robberSupply,10);
      if (seed == 0)
      {
        address robber = gallery.randomRobber(seed);
        //catsNapped += 1;
        return robber;
      } else {
        return msg.sender;
      }


  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    // This will pay HashLips 5% of the initial sale.
    // You can remove this if you want, or keep it in to support HashLips and his channel.
    // =============================================================================
    (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: address(this).balance * 5 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}