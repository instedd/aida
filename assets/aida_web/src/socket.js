import { Socket } from 'phoenix/phoenix'

const socket = new Socket('ws://app.aida.lvh.me/socket')
socket.connect()

export default socket
