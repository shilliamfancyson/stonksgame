import React, {useEffect, useState} from 'react';
import {ethers} from 'ethers';
import abi from '../contracts/abi.json'


const WalletCard = () => {

    //const contractAddress = '0xfa7C260feD8525847Da41E52e9d9795834CB9DB8';
    const contractAddress = '0x09B96c0AA4052fD6476CF2E8dF2CFA90005B8F8d';
    const [errorMessage, setErrorMessage] = useState(null);
	const [defaultAccount, setDefaultAccount] = useState(null);
	const [userBalance, setUserBalance] = useState(null);
	const [connButtonText, setConnButtonText] = useState('Connect Wallet');

    const [provider, setProvider] = useState(null);
    const [signer, setSigner] = useState(null);
    const [contract, setContract] = useState(null);

    const [nfts, setNfts] = useState(null);

    const connectWalletHandler = () => {
		if (window.ethereum && window.ethereum.isMetaMask) {
			console.log('MetaMask Here!');

			window.ethereum.request({ method: 'eth_requestAccounts'})
			.then(result => {
				accountChangedHandler(result[0]);
				setConnButtonText('Wallet Connected');
				getAccountBalance(result[0]);
			})
			.catch(error => {
				setErrorMessage(error.message);
			
			});

		} else {
			console.log('Need to install MetaMask');
			setErrorMessage('Please install MetaMask browser extension to interact');
		}
	}

	// update account, will cause component re-render
	const accountChangedHandler = (newAccount) => {
		setDefaultAccount(newAccount);
		getAccountBalance(newAccount.toString());
        updateEthers();
	}

    const updateEthers = () => {
        let tempProvider = new ethers.providers.Web3Provider(window.ethereum);
        let tempSigner = tempProvider.getSigner();

        let tempContract = new ethers.Contract(contractAddress, abi, tempSigner)

        setProvider(tempProvider);
        setSigner(tempSigner);
        setContract(tempContract);
    }

    useEffect(() =>{

        if (contract != null){
            updateStonks();
        }

    }, [contract])
    
    const updateStonks = async () => {
        // console.log(provider.getCode(contract));
        let account = '0x08Ae07292bdfB4b56a0a5B1d5196c51CD8208Fa6';
        let tokenIds = await contract.stakedNFTSByUser('0x08Ae07292bdfB4b56a0a5B1d5196c51CD8208Fa6');

        let ids = [];
        for (let i = 0; i < tokenIds.length; i++)
        {
            let id = tokenIds[i].toNumber();
            if (id != 0){
                
                ids.push(id);
                console.log(id);
                let marketInfo = await contract.market(id);
                console.log(marketInfo[1].toNumber());
            }
            
        }

        



        
        console.log(ids);
        setNfts(ids.length);
    }

	const getAccountBalance = (account) => {
		window.ethereum.request({method: 'eth_getBalance', params: [account, 'latest']})
		.then(balance => {
			setUserBalance(ethers.utils.formatEther(balance));
		})
		.catch(error => {
			setErrorMessage(error.message);
		});
	};

	const chainChangedHandler = () => {
		// reload the page to avoid any errors with chain change mid use of application
		window.location.reload();
	}


	// listen for account changes
	window.ethereum.on('accountsChanged', accountChangedHandler);

	window.ethereum.on('chainChanged', chainChangedHandler);

    return (
		<div className='walletCard'>
		<h4> {"Connection to MetaMask using window.ethereum methods"} </h4>
			<button onClick={connectWalletHandler}>{connButtonText}</button>
			<div className='accountDisplay'>
				<h3>Address: {defaultAccount}</h3>
			</div>
			<div className='balanceDisplay'>
				<h3>Balance: {userBalance}</h3>
			</div>

            <div className='NFTDisplay'>
				<h3>NFTS: {nfts}</h3>
			</div>
			{errorMessage}
		</div>
	);
}
export default WalletCard;