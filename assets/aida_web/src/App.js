import React, { Component } from 'react'
import './App.css'
import '../node_modules/react-md/dist/react-md.light_blue-deep_orange.min.css'
import BotIndex from './BotIndex'
import { Toolbar } from 'react-md'

class App extends Component {

  render() {
    return (
      <div className='body'>
        <Toolbar className='header'
          colored
          prominent
          // nav={}
          title='Aida Admin'
          // actions={}
        />
        <div className='sidebar' />
        <div className='main'>
          <BotIndex />

        </div>
        <div className='footer'>
          This is the footer
        </div>
      </div>
    )
  }
}

export default App
