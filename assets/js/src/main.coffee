async = require 'async'

Form          = require './form'
Record        = require './record'
map_utils     = require './map_utils'
form_utils    = require './form_utils'
record_utils  = require './records/utils'
RecordViewer  = require './records/viewer'
RecordCreator = require './records/creator'
AlertCreator  = require './alerts/creator'

jQuery.fn.serializeObject = ->
  arrayData = @serializeArray()
  objectData = {}

  $.each arrayData, ->
    if @value?
      value = @value
    else
      value = ''

    if objectData[@name]?
      unless objectData[@name].push
        objectData[@name] = [objectData[@name]]

      objectData[@name].push value
    else
      objectData[@name] = value

  return objectData

class App
  init: ->
    @map = map_utils.createMap 'map-container'
    @initEvents()
    async.parallel {form: @getForm, records: @getRecords, alert_form: @getAlertForm}, @formAndRecordsCallback

  initEvents: ->
    $('#new-record-a').on 'click', (event) =>
      event.preventDefault()
      record_creator = new RecordCreator @form, @
    $('#new-alert-a').on 'click', (event) =>
      event.preventDefault()
      alert_creator = new AlertCreator @alert_form, @

  getForm: (callback) ->
    form_utils.getForm (error, form) ->
      if error
        callback error
      else
        callback null, form

  getRecords: (callback) ->
    record_utils.getRecords (error, records) ->
      if error
        callback error
      else
        callback null, records

  getAlertForm: (callback) ->
    form_utils.getAlertForm (error, alert_form) ->
      if error
        callback error
      else
        callback null, alert_form

  getRecord: (callback) ->
    record_utils.getRecord (error, record) ->
      if error
        callback error
      else
        callback null, record


  addRecord: (record_as_feature) ->
    @features_layer.addData record_as_feature

  nameApp: (app_name) ->
    document.title = app_name
    $('#brand').text app_name

  displayCurrentRecord: (error, results) ->
    if error
      console.log error
      return

    form_json   = results.form
    record_json = results.record

    @form = new Form form_json

    record = new Record record_json, @form
    record_display = new RecordViewer @form, record

  formAndRecordsCallback: (error, results) =>
    if error
      console.log error
      return

    form_json       = results.form
    alert_form_json = results.alert_form
    records         = results.records

    @form       = new Form form_json
    @alert_form = new Form alert_form_json

    @nameApp @form.name()

    geojson_layer_options =
      onEachFeature: (feature, layer) =>
        layer.on 'click', =>
          record = new Record feature, @form
          record_display = new RecordViewer @form, record
    @features_layer = map_utils.createGeoJSONLayer geojson_layer_options

    @map.addLayer @features_layer

    @features_layer.addData records
    @map.fitBounds @features_layer.getBounds()

    async.parallel {form: @getForm, record: @getRecord}, @displayCurrentRecord

app = new App()
app.init()
