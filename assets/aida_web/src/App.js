import React, { Component } from 'react'
import logo from './logo.svg'
import './App.css'
import ManifestForm from './ManifestForm'
import ManifestIndex from './ManifestIndex'

class App extends Component {

  render() {
    return (
      <div className='body'>
        <div className='header'>
          <img src={logo} className='logo' alt='logo' />
          <h1>Welcome to React</h1>
        </div>
        <div className='sidebar' />
        <div className='main'>
          <ManifestIndex />
          <ManifestForm />
        </div>
        <div className='footer'>
          This is the footer
        </div>
      </div>
    )
  }
}

export default App
