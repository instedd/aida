import React, { Component } from 'react'
import * as api from './api'
import { Button, TextField } from 'react-md'
import PropTypes from 'prop-types'

class BotForm extends Component {
  constructor(props) {
    super(props)
    this.state = {
      manifest: ''
    }

    this.updateManifest = this.updateManifest.bind(this)
  }

  createBot() {
    api.createBot(this.refs.text.value).then(() => {
      this.props.afterCreate()
      this.setState({ manifest: '' })
    })
  }

  updateManifest(manifest) {
    this.setState({ manifest: manifest })
  }

  render() {
    return (
      <div className='main-container'>
        <div className='content'>
          <TextField ref='text'
            label='Manifest'
            rows={2}
            id='manifest-input'
            value={this.state.manifest}
            onChange={this.updateManifest}
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
