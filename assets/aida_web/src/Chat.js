import React, { Component } from 'react'
import socket from './socket'
import map from 'lodash/map'
import { Button, List, ListItem, TextField } from 'react-md'

// just for testing on the console
window.socket = socket

class Chat extends Component {
  constructor(props) {
    super(props)
    this.state = {
      messages: [],
      botId: '',
      sessionId: '',
      channel: null
    }
  }

  join() {
    let { channel } = this.state
    if (channel) { channel.leave() }
    this.setState({ botId: this.refs.botId.value })

    const { botId, accessToken } = this.refs
    channel = socket.channel(`bot:${botId.value}`, {'access_token': accessToken.value})

    channel.join()
      .receive('ok', resp => {
        console.log('Joined successfully', resp)
      })
      .receive('error', resp => { console.log('Unable to join', resp) })

    channel.on('btu_msg', payload => {
      console.log(`[${Date()}] ${payload.text}`)
      const { messages } = this.state

      this.setState({
        messages: [
          ...messages,
          payload.text
        ]
      })
    })

    this.setState({ channel: channel })
  }

  sendMessage() {
    let { sessionId, channel, messages } = this.state

    this.setState({
      messages: [
        ...messages,
        this.refs.chatInput.value
      ]
    })

    channel.push('utb_msg', {session: sessionId, text: this.refs.chatInput.value})
  }

  getNewSession() {
    let { channel } = this.state

    channel
      .push('new_session', {})
      .receive('ok', resp => {
        console.log('New Session', resp)
        this.setState({ sessionId: resp.session })
      })
  }

  render() {
    const { messages } = this.state

    return (
      <div className='main-container'>
        <div className='content'>
          <List>
            {map(messages, (message, index) =>
              <ListItem primaryText={message} key={index} />
            )}
          </List>
          <TextField ref='chatInput'
            label='What say you?'
            id='chat-input'
            className='md-cell md-cell--bottom'
          />
        </div>
        <div className='actions'>
          <Button onClick={() => this.sendMessage()} raised >Send</Button>
          <TextField ref='botId'
            label='bot id'
            id='bot-id'
            className='md-cell md-cell--bottom'
          />
          <TextField ref='accessToken'
            label='access token'
            id='access-token'
            className='md-cell md-cell--bottom'
          />
          <Button onClick={() => this.join()} raised >Join</Button>
          <Button onClick={() => this.getNewSession()} raised >New Session</Button>
        </div>
      </div>
    )
  }
}

export default Chat
