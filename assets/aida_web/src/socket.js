import { Socket } from 'phoenix'
import get from 'lodash/get'

const socket = new Socket(get(process.env, 'REACT_APP_WEB_SOCKET'))
socket.connect()

export default socket
