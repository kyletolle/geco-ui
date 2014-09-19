xhr  = require 'xhr'

map_utils     = require '../map_utils'

panelBody = (panel_body_html) ->
  "<div class='panel-body'>#{panel_body_html}</div>"

panel = (panel_html) ->
  "<div class='panel panel-default'>#{panel_html}</div>"

form = (form_html) ->
  ""

formGroup = (form_group_html, css_class, required) ->
  css_class = if css_class then " #{css_class}" else ''
  if required
    css_class += ' required'
  "<div class='form-group#{css_class}'>#{form_group_html}</div>"

class AlertCreator
  constructor: (@form, @app) ->
    @$modal_container    = $($('#new-alert-modal-template').html())
    @$html_form          = @$modal_container.find('form')
    @$saved_alert_modal = $('#saved-alert-modal')

    @init()

  formSubmit: ->
    form_obj = @$html_form.serializeObject()

    latitude  = 0.0
    longitude = 0.0

    record =
      latitude: latitude
      longitude: longitude
      form_id: @form.id()
      form_values: form_obj
    data =
      record: record
    xhr_options =
      uri: '/api/records'
      method: 'POST'
      json: data
    xhr_callback = (error, response, record_as_feature) =>
      if error
        window.alert response.body
        return
      @$saved_alert_modal.modal 'show'
      @$modal_container.modal 'hide'
      setTimeout =>
        @$saved_alert_modal.modal 'hide'
      , 2000
    xhr xhr_options, xhr_callback

  initEvents: ->
    @$html_form.on 'submit', (event) =>
      event.preventDefault()
      event.stopPropagation()
      @formSubmit()
    @$modal_container.on 'hidden.bs.modal', (event) =>
      @destroy()

  #
  # Elements
  #

  generateTextField: (element) ->
    input_type = if element.numeric then 'number' else 'text'
    panel panelBody(formGroup("<label>#{element.label}</label><input type='#{input_type}' class='form-control' data-fulcrum-field-type='#{element.type}' id='#{element.key}' name='#{element.key}'>", null, element.required))

  #
  # /Elements
  #

  generateElement: (element) ->
    if @["generate#{element.type}"]
      html = @["generate#{element.type}"](element)
    else
      console.log "Could not render element #{element.type}"
      html = ''
    html

  generateHTMLContent: ->
    parts =
      [
        "<p>By subscribing to alerts, you will receive email and/or text alerts when someone creates a new happening during GeCo in the Rockies 2014.</p>",
        "<p>Don't worry, the emails and phone numbers are only for use in this little application and will be deleted at the end of GeCo in the Rockies 2014.</p>"
      ]
    for element in @form.form_obj.elements
      parts.push @generateElement element
    @html_content = parts.join ''

  init: ->
    @initEvents()
    @generateHTMLContent()
    @$modal_container.find('.modal-body').find('.content').html @html_content
    @$modal_container.modal()

  destroy: ->
    @$modal_container.find('.modal-body').find('.content').html ''
    @$modal_container.modal 'hide'

module.exports = AlertCreator
