import React, { Component } from 'react'
import * as api from './api'
import map from 'lodash/map'
import { Button, List, ListItem } from 'react-md'
import BotForm from './BotForm'

class BotIndex extends Component {
  constructor(props) {
    super(props)
    this.state = {
      bots: []
    }
  }

  componentWillMount() {
    this.refreshBots()
  }

  refreshBots() {
    api.fetchBots().then((response) => {
      this.setState({bots: response || []})
    })
  }

  deleteBot(bot) {
    api.deleteBot(bot).then(() =>
      this.refreshBots()
    )
  }

  use(bot) {
    document.getElementById('bot-id').value = bot.id
  }

  render() {
    const { bots } = this.state

    return (
      <div className='main-container'>
        <h2 className='tabvar'>Bots</h2>
        <List className='content'>
          {map(bots, (bot) =>
            <ListItem primaryText={bot.id} key={bot.id} >
              <Button onClick={() => this.use(bot)} flat>Use</Button>
              <Button onClick={() => this.deleteBot(bot)} flat secondary>Delete</Button>
            </ListItem>
          )}
        </List>
        <BotForm afterCreate={() => this.refreshBots()} />
      </div>
    )
  }
}

export default BotIndex
