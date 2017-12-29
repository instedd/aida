import React, { Component } from 'react'
import './App.css'
import '../node_modules/react-md/dist/react-md.light_blue-deep_orange.min.css'
import BotIndex from './BotIndex'
import Chat from './Chat'
import { Toolbar } from 'react-md'
import * as api from './api'

class App extends Component {
  constructor(props) {
    super(props)
    this.state = {
      version: ''
    }
  }

  componentWillMount() {
    api.fetchVersion().then((response) => {
      this.setState({version: response || ''})
    })
  }

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
          <Chat />
        </div>
        <div className='footer'>
          Version: {this.state.version}
        </div>
      </div>
    )
  }
}

export default App
