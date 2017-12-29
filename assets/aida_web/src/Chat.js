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

  setBotId() {
    let { channel } = this.state
    if (channel) { channel.leave() }
    this.setState({ botId: this.refs.botId.value })

    channel = socket.channel(`bot:${this.refs.botId.value}`, {})

    channel.join()
      .receive('ok', resp => {
        console.log('Joined successfully', resp)
        this.setState({ sessionId: resp.session_id })
      })
      .receive('error', resp => { console.log('Unable to join', resp) })

    channel.on('btu_msg', payload => {
      console.log(`[${Date()}] ${payload.text}`)
      const { messages } = this.state

      this.setState({
        messages: [
          ...messages,
          [Date(), payload.text]
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
        [Date(), this.refs.chatInput.value]
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
            {map(messages, (message) =>
              <ListItem primaryText={message[1]} key={message[0]} />
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
            id='chat-input'
            className='md-cell md-cell--bottom'
          />
          <Button onClick={() => this.setBotId()} raised >Set Bot Id</Button>
          <Button onClick={() => this.getNewSession()} raised >New Session</Button>
        </div>
      </div>
    )
  }
}

export default Chat
