API for interacting with the Chatbot Client
===

This API was developed with the intention of communicating two applications: the AIDA backend Phoenix application with a frontend application to filter and redirect messages to a client. When interacting with this API take into account that it was not meant for a single client, but for the communication of systems.

The protocol is based on [Phoenix channels](https://hexdocs.pm/phoenix/channels.html). This means that this API uses the standard set by Phoenix for websocket communications.

Endpoint for the websocket: `wss://AIDA-SERVER/socket`

## Setting up a session

A session corresponds to a series of messages exchanged between the bot and a specific user and it has an identifier.

#### Message type: `join`

To set up a channel it will be necessary to have the bot UUID and an access token of your choosing. Join the socket by sending a message with the UUID and the access token, the server will return “unauthorized” if the bot UUID doesn’t exist.

Sample code:

```javascript
let socket = new Socket('wss://AIDA-SERVER/socket')

let channel = socket.channel(`bot:${botId}`, {'access_token': accessToken})

channel.join()
  .receive('ok', resp => {
    console.log('Joined successfully', resp)
  })
  .receive('error', resp => { console.log('Unable to join', resp) })
```

#### Message type: `new_session`

Pushing `new_session` starts a new thread of messages, server will reply with `session`, be sure to save that session ID.
There’s an optional parameter `data`: Whatever is sent here will be merged into the session data. Common uses are setting first and last name, as given by Facebook through their channel.

Sample code:

```javascript
channel
  .push('new_session', {})
  .receive('ok', resp => {
    console.log('New Session', resp.session)
  })
```

#### Message type: `delete_session`
Additional params: `{session: session_id}`

Sending this will delete all data about the session, and it will not be available to be reused.

## Sending messages

Once a session is established messages can be sent, always adding the session ID as a parameter. Everytime the session ID is included that session can be reused.

#### Message type: `utb_msg`
Additional params: `{session: session_id, text: text}`

All messages input by the user interacting with the bot should be sent with this message.

Sample code:

```javascript
channel.push('utb_msg', {session: sessionId, text: 'the message'})
```

#### Message type: `put_data`
Additional params: `{session: session_id, data: data}`

Same data as can be input during the opening of the session. Whatever is sent is incorporated to the session data. Used for sending `first_name` and `last_name`

### Sending images

Sending images is a two-step process. First of all, clients must perform a POST request (not via websocket) to `https://AIDA_SERVER/content/image/<BOT_UUID>/<SESSION_UUID>` with the file attached in a `file` field of a form data.

The server will respond with a JSON object like `{id: "IMAGE_UUID"}`.

The image can be retrieved (ie, for rendering on the client) via a GET request to `https://AIDA_SERVER/content/image/<IMAGE_UUID>`.

Once the image has been uploaded, the client should push that image’s UUID through the channel by sending a `utb_img` message.

#### Message type: `utb_img`
Additional params: `{session: session_id, image: image_uuid}`

The `image_uuid` must correspond to an image the current session has already attached for this specific bot.

Sample code:

```javascript
channel.push('utb_msg', {session: session_id, image: image_uuid})
```

## Receiving messages

The channel created to set up a session should be capable of listening to incoming `btu_msg` sent from the server.

#### Message type: `btu_msg`
Additional params: `{session: session_id, text: text}`

The text in the incoming message  is the answer from the bot the user. It should be handled on the client end to be shown as a response.

Since this API wasn’t thought out for a single client, it will be necessary to filter incoming btu messages to find the appropriate session ID for the session in progress.

Sample code:

```javascript
channel.on('btu_msg', payload => {
  if (this.sessionId === payload.session) {
    console.log(`[${Date()}] ${payload.text}`)
  }
})
```
