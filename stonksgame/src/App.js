import logo from './logo.svg';
import './App.css';
import Home from './Home.js';
import Game from './Game.js';
import {Route, Link, Routes, BrowserRouter, Switch, Router} from 'react-router-dom';

function App() {
  return (
    <div className="App">
      <Routes>
      <Route exact path="/" element={<Home/>}/>
      <Route exact path="/game" element={<Game/>}/>
      </Routes>

      
      
    </div>
  );
}

export default App;
