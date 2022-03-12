const stockdata = require('node-stock-data');
const express = require("express");
const https = require('https');
const axios = require('axios');
const ccxt = require('ccxt');

const PORT = process.env.PORT || 3001;

const app = express();

app.get("/stock", async (req, res) => {

    const price = await testStockData('AAPL');

    res.sendStatus(price);
})

app.get("/crypto", async (req, res) => {
    const data = await getCryptoData('BTC/USDT');
    res.json({message: data});
})

async function testStockData(ticker){

    const url = "https://eodhistoricaldata.com/api/eod/MCD.US?from=2017-01-05&to=2017-02-10&period=d&fmt=json&api_token=622a27e95fe1d2.39252143";
    const data = await axios.get(url);
    const price = data['data'][0]['adjusted_close'];
    console.log(price);

    return price;

}

async function getCryptoData(ticker){
    var data = await new ccxt.binance().fetchTicker(ticker);
    
    data = data['last'];
    // console.log(data['last'])
    return data;
}

app.listen(PORT, () => {
  console.log(`Server listening on ${PORT}`);
});