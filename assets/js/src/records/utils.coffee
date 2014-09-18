xhr = require 'xhr'

getRecords = (cb) ->
  xhr_options =
    uri: '/api/records'
    json: true
  xhr_callback = (error, response, records) ->
    if error
      cb error, null
    else
      cb null, records
  xhr xhr_options, xhr_callback

getParameterByName = (name) ->
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
  results = regex.exec(location.search)
  results == null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "))

  if results == null
    return ""
  else
    return decodeURIComponent(results[1].replace(/\+/g, " "))

getRecord = (cb) ->
  record_id = getParameterByName('record_id')

  xhr_options =
    uri: '/api/record/' + record_id
    json: true
  xhr_callback = (error, response, record) ->
    if error
      cb error, null
    else
      cb null, record
  if !!$.param('record_id')
    xhr xhr_options, xhr_callback

module.exports =
  getRecords: getRecords
  getRecord: getRecord
