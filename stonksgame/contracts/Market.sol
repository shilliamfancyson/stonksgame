// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;
import "./IERC721Receiver.sol";
import "./FISH.sol";
import "./Cat.sol";

contract Market is Ownable, IERC721Receiver{

    //struct to store a stake's token, owner, earnings
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint256 price;
    }

    mapping (address => uint256[]) public stakePortfolioByUser;

    /// tokenId => indexInStakePortfolio
    mapping(uint256 => uint256) public indexOfTokenIdInStakePortfolio;
    //add events
    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event StonkClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    //reference stonk NFT contract
    Stonk stonk;
    //reference to $TICKET contract for minting earnings
    FISH coin;

    // reference to Entropy
    // IEntropy entropy;

    //maps tokenId to stake
    mapping(uint256 => Stake) public market;
    //maps rarity to all robbers stakes with that rarity
    mapping(uint256 => Stake) public group;
    //track location of robber in group
    mapping(uint256 => uint256) public groupIndices;

    //total rarity scores stakes
    uint256 public totalRarityStaked = 0;
    //any rewards distributed when no CNs are staked
    uint256 public unaccountedRewards = 0;
    //amount of $COIN due for each rarity point staked
    uint256 public coinsPerRarityScore = 0;

    uint256 public coinForRobbers = 0;

    // Portaits earn 10000 $COIN per day
    uint256 public constant DAILY_COIN_RATE = 100000000000000000;
    // paintinggs must have 2 days worth of $TICKET to unstake or else i
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // Robbers take a 15% tax on all $Robbers claimed
    uint256 public constant COIN_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 1.8 billion $TICKET earned through staking
    uint256 public constant MAXIMUM_GLOBAL_COINS = 1800000000000000000000;

    // amount of $TICKET earned so far
    uint256 public totalCoinEarned;
    // number of Paintings staked in the Hotel
    uint256 public totalStonksStaked;
    // the last time $TICKET was claimed
    uint256 public lastClaimTimestamp;

    uint256 public totalRobbersStaked = 0;

    


    
    constructor(address _stonk, address _coin) {
        stonk = Stonk(_stonk);
        coin = FISH(_coin);
    }

    /** STAKING */
    
    /**
     * adds Painting and Robbers to the Gallery and Group
     * @param account the address of the staker
     * @param tokenIds the IDs of the painting and Robbers to stake
     */
    function addManyToMarketAndGroup(address account, uint256[] calldata tokenIds, uint256[] calldata prices)
        public
    {
        // require(
        //     account == _msgSender() || _msgSender() == address(cat),
        //     "DO NOT GIVE YOUR TOKENS AWAY"
        // );
        // require(tx.origin == _msgSender());

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // to ensure it's not in buffer
            // require(cat.totalSupply() >= tokenIds[i] + cat.maxMintAmount());
            
            if (_msgSender() != address(stonk)) {
                // dont do this step if its a mint + stake
                require(
                    stonk.ownerOf(tokenIds[i]) == _msgSender(),
                    "NOT YOUR TOKEN"
                );
                //cat.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (isStonk(tokenIds[i])){
             _addStonkToMarket(account, tokenIds[i], prices[i]);
            }
            // else {
            // _addRobberToGroup(account, tokenIds[i]);
            // }
        }
    }
    
    /**
     * adds a single painting to the Gallery
     * @param account the address of the staker
     * @param tokenId the ID of the Sheep to add to the Barn
     */
    function _addStonkToMarket(address account, uint256 tokenId, uint256 price)
        public
        // whenNotPaused
        // _updateEarnings
    {
        stonk.transferFrom(_msgSender(), address(this), tokenId);

        market[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp),
            price: uint256(price)
        });

        stakePortfolioByUser[_msgSender()].push(tokenId);
        uint256 indexOfNewElement = stakePortfolioByUser[_msgSender()].length - 1;
        indexOfTokenIdInStakePortfolio[tokenId] = indexOfNewElement;
        //cat.approve(address(this), 1);
        totalStonksStaked += 1;
        

        emit TokenStaked(account, tokenId, block.timestamp);
    }

    // function _addRobberToGroup(address account, uint256 tokenId) public {
        
    //     painting.transferFrom(_msgSender(), address(this), tokenId);

    //     group[tokenId] = Stake({
    //         owner: account,
    //         tokenId: uint16(tokenId),
    //         value: uint80(block.timestamp)
    //     });

    //     totalRobbersStaked += 1;

    //     emit TokenStaked(account, tokenId, block.timestamp);
    // }

    /** CLAIMING / UNSTAKING */
    function claimManyFromMarketAndGroup(uint16[] calldata tokenIds, bool unstake, uint256 volume, uint256[] calldata prices)
    external
    // _updateEarnings
    {
        require(tx.origin == _msgSender());

        uint256 owed = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isStonk(tokenIds[i])){

            owed += _claimStonkFromMarket(tokenIds[i], unstake, volume, prices[i]);

            } else {

            // owed += _claimRobberFromGroup(tokenIds[i], unstake);

            }
        }

        if (owed == 0) return;

        coin.mint(_msgSender(), owed);
    }


    function _claimStonkFromMarket(uint256 tokenId, bool unstake, uint256 volume, uint256 currPrice)
    internal
    returns (uint256 owed)
    {
        Stake memory stake = market[tokenId];

        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");

        owed = ((block.timestamp - stake.value) * DAILY_COIN_RATE * volume) / 1 days;

        if (unstake){

            //50% chance to have all $TICKETs stolen
            // if (painting.generateSeed(totalCatsStaked,10) > 5){
            //     _payRobberTax(owed);
            //     owed = 0;
            // }
            

            totalStonksStaked -= 1;
                    
            //send back painting
            stonk.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            delete market[tokenId];
            stakePortfolioByUser[_msgSender()][indexOfTokenIdInStakePortfolio[tokenId]] = 0;
        } else {
            
            // _payRobberTax((owed * TICKET_CLAIM_TAX_PERCENTAGE)/100);

            owed = (owed * (100 - COIN_CLAIM_TAX_PERCENTAGE)) / 100;

            market[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp),
                price: uint256(currPrice)
            });

        
        }
        
        

        emit StonkClaimed(tokenId, owed, unstake);

    }

    // function _claimRobberFromGroup(uint256 tokenId, bool unstake) internal returns (uint256){
    //     require(
    //         painting.ownerOf(tokenId) == address(this),
    //         "NOT THE OWNER"
    //     );

    //     Stake memory stake = group[tokenId];

    //     require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");

    //     uint256 owed = ticketForRobbers / totalRobbersStaked;

    //     if (unstake){
            
    //         totalRobbersStaked -= 1;

            

    //         delete group[tokenId];

    //         painting.safeTransferFrom(address(this), _msgSender(), tokenId,"");
    //     } else {
        
    //         group[tokenId] = Stake({
    //             owner: _msgSender(),
    //             tokenId: uint16(tokenId),
    //             value: uint80(block.timestamp)
    //         });

    //     }
    //     emit RobberClaimed(tokenId, owed, unstake);
    // }

    // function randomRobber(uint256 seed) external view returns(address){

    //     if (totalRobbersStaked == 0){
    //         return address(0x0);
    //     }
    //     return address(0x0);


    // }

    function isStonk(uint256 tokenId) public view returns (bool){
        if (tokenId >= 45000){
            return false;
        }
        return true;
    }

    function stakedNFTSByUser(address owner) external view returns (uint256[] memory){
        return stakePortfolioByUser[owner];
    }

    // function _payRobberTax(uint256 amount) internal {
    //     if (totalRobbersStaked == 0){
    //         unaccountedRewards += amount;
    //         return;
    //     }

    //     ticketForRobbers += amount + unaccountedRewards;
    //     unaccountedRewards = 0;
        
    // }
    
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }


}