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
            defaultValue={`{
              "version": 1,
              "languages": ["en","es"],
              "front_desk": {
                "greeting": {
                  "message": {
                    "en": "Hello, I'm a Restaurant bot",
                    "es": "Hola, soy un bot de Restaurant"
                  }
                },
                "introduction": {
                  "message": {
                    "en": "I can do a number of things",
                    "es": "Puedo ayudarte con varias cosas"
                  }
                },
                "not_understood": {
                  "message": {
                    "en": "Sorry, I didn't understand that",
                    "es": "Perdón, no entendí lo que dijiste"
                  }
                },
                "clarification": {
                  "message": {
                    "en": "I'm not sure exactly what you need.",
                    "es": "Perdón, no estoy seguro de lo que necesitás."
                  }
                },
                "threshold": 0.7
              },
              "skills": [
                {
                  "type": "keyword_responder",
                  "explanation": {
                    "en": "I can give you information about our menu",
                    "es": "Te puedo dar información sobre nuestro menu"
                  },
                  "clarification": {
                    "en": "For menu options, write 'menu'",
                    "es": "Para información sobre nuestro menu, escribe 'menu'"
                  },
                  "keywords": {
                    "en": ["menu","food"],
                    "es": ["menu","comida"]
                  },
                  "response": {
                    "en": "We have {food_options}",
                    "es": "Tenemos {food_options}"
                  }
                },
                {
                  "type": "keyword_responder",
                  "explanation": {
                    "en": "I can give you information about our opening hours",
                    "es": "Te puedo dar información sobre nuestro horario"
                  },
                  "clarification": {
                    "en": "For opening hours say 'hours'",
                    "es": "Para información sobre nuestro horario escribe 'horario'"
                  },
                  "keywords": {
                    "en": ["hours","time"],
                    "es": ["horario","hora"]
                  },
                  "response": {
                    "en": "We are open every day from 7pm to 11pm",
                    "es": "Abrimos todas las noches de 19 a 23"
                  }
                }
              ],
              "variables": [
                {
                  "name": "food_options",
                  "values": {
                    "en": "barbecue and pasta",
                    "es": "parrilla y pasta"
                  }
                }
              ],
              "channels": [
                {
                  "type": "facebook",
                  "page_id": "1234567890",
                  "verify_token": "qwertyuiopasdfghjklzxcvbnm",
                  "access_token": "QWERTYUIOPASDFGHJKLZXCVBNM"
                }
              ]
            }`}
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
