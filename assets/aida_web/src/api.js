import 'isomorphic-fetch'
import get from 'lodash/get'

export class Unauthorized {
  constructor(response) {
    this.response = response
  }
}

const apiFetch = (url, options) => {
  const baseUrl = get(process.env, 'REACT_APP_API_BASE_URL') || ''
  return fetch(`${baseUrl}/api/${url}`, { ...options, credentials: 'same-origin' })
    .then(response => {
      return handleResponse(response, () => response)
    })
}

const commonCallback = (json) => {
  return () => {
    if (!json) { return null }
    if (json.errors) {
      console.log(json.errors)
    }
    return json.data
  }
}

const apiFetchJSON = (url, options) => {
  return apiFetchJSONWithCallback(url, options, commonCallback)
}

const apiFetchJSONWithCallback = (url, options, responseCallback) => {
  return apiFetch(url, options)
      .then(response => {
        if (response.status === 204) {
          // HTTP 204: No Content
          return { json: null, response }
        } else {
          return response.json().then(json => ({ json, response }))
        }
      })
      .then(({ json, response }) => {
        return handleResponse(response, responseCallback(json))
      })
}

const handleResponse = (response, callback) => {
  if (response.ok) {
    return callback()
  } else if (response.status === 401 || response.status === 403) {
    return Promise.reject(new Unauthorized(response.statusText))
  } else {
    return Promise.reject(response)
  }
}

const apiPutOrPostJSON = (url, verb, body) => {
  return apiPutOrPostJSONWithCallback(url, verb, body, commonCallback)
}

const apiPutOrPostJSONWithCallback = (url, verb, body, callback) => {
  const options = {
    method: verb,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  }
  if (body) {
    options.body = JSON.stringify(body, { separator: '_' })
  }
  return apiFetchJSONWithCallback(url, options, callback)
}

const apiPostJSON = (url, body) => {
  return apiPutOrPostJSON(url, 'POST', body)
}

const apiDelete = (url) => {
  return apiFetch(url, {method: 'DELETE'})
}

export const fetchBots = () => {
  return apiFetchJSON(`bots`)
}

export const fetchVersion = () => {
  return apiFetchJSON(`version`)
}

export const createBot = (manifest) => {
  return apiPostJSON(`bots`, {bot: {manifest}})
}

export const deleteBot = (bot) => {
  return apiDelete(`bots/${bot.id}`)
}
