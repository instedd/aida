import React, { Component } from 'react'
import * as api from './api'
import { Button, TextField } from 'react-md'
import PropTypes from 'prop-types'

class BotForm extends Component {
  createBot() {
    api.createBot(this.refs.text.value).then(() =>
      this.props.afterCreate()
    )
  }

  render() {
    return (
      <div className='main-container'>
        <div className='content'>
          <TextField ref='text' style={{minHeight: '200px', width: '100%'}}
            label='Manifest'
            rows={2}
            id='manifest-input'
            className='md-cell md-cell--bottom'
          />
        </div>
        <div className='actions'>
          <Button onClick={() => this.createBot()} raised primary>Create</Button>
        </div>
      </div>
    )
  }
}

BotForm.propTypes = {
  afterCreate: PropTypes.func.isRequired
}

export default BotForm
