xhr = require 'xhr'

map_utils = require '../map_utils'

panelBody = (panel_body_html) ->
  "<div class='panel-body'>#{panel_body_html}</div>"

panel = (panel_html) ->
  "<div class='panel panel-default'>#{panel_html}</div>"

form = (form_html) ->
  ""

formGroup = (form_group_html) ->
  "<div class='form-group'>#{form_group_html}</div>"

class Creator
  constructor: (@form) ->
    @$modal_container = $('#new-record-modal')
    @$map_container   = @$modal_container.find('.new-record-map-container')
    @$html_form       = @$modal_container.find('form')

    @init()

  createMap: ->
    @map = map_utils.createMap @$map_container[0], {zoomControl: false}
    @map.on 'moveend', @mapMove

    locate_control = L.control.locate({follow: true, stopFollowingOnDrag: true})
    locate_control.addTo @map
    locate_control.locate()

  mapMove: =>
    center = @map.getCenter()
    $('#latitude').val center.lat
    $('#longitude').val center.lng

  formSubmit: ->
    form_obj = @$html_form.serializeObject()

    latitude  = parseFloat form_obj.latitude
    longitude = parseFloat form_obj.longitude
    delete form_obj.latitude
    delete form_obj.longitude

    choice_field_keys = @form.choiceFieldKeys()
    console.log choice_field_keys
    console.log form_obj

    # TODO: Support "other" values
    for choice_field_key in choice_field_keys
      if choice_field_key of form_obj
        value_or_values = form_obj[choice_field_key]
        value_or_values = if value_or_values instanceof Array then value_or_values else [value_or_values]
        form_obj[choice_field_key] =
          choice_values: value_or_values
          other_values: []

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
    xhr_callback = (error, response, record_obj) =>
      if error
        window.alert response.body
        return
      console.log record_obj
      window.alert 'saved!'
      @destroy()
    xhr xhr_options, xhr_callback

  initBeforeEvents: ->
    @$html_form.on 'submit', (event) =>
      event.preventDefault()
      event.stopPropagation()
      @formSubmit()
    @$modal_container.on 'shown.bs.modal', (event) =>
      # We need to make sure animations are finished before creating the map
      @createMap()
    #@$modal_container.on 'hide.bs.modal', (event) =>
    #  @map.remove()

  initAfterEvents: ->
    $('.yes-no').on 'click', (event) =>
      event.preventDefault()
      $button = $(event.target)
      $button.siblings('a.yes-no').removeClass 'active'
      $button.addClass 'active'
      $("##{$button.data('input-id')}").val $button.data('yes-no-val')

  #
  # Elements
  #
  generateLabel: (element) ->
    "<div class='alert alert-info'>#{element.label}</div>"

  generateSection: (element) ->
    html_parts = []
    for inner_element in element.elements
      inner_element_html = @generateElement inner_element
      html_parts.push panelBody(inner_element_html)
      html = panel(html_parts.join '')
    panel "<div class='panel-heading'><h3 class='panel-title'>#{element.label}</h3></div>#{panelBody(html)}"

  generateTextField: (element) ->
    input_type = if element.numeric then 'number' else 'text'
    panel panelBody(formGroup("<label>#{element.label}</label><input type='#{input_type}' class='form-control' data-fulcrum-field-type='#{element.type}' id='#{element.key}' name='#{element.key}'>"))

  generateDateTimeField: (element) ->
    panel panelBody(formGroup("<label>#{element.label}</label><input type='date' class='form-control' data-fulcrum-field-type='#{element.type}' id='#{element.key}' name='#{element.key}'>"))

  generateTimeField: (element) ->
    panel panelBody(formGroup("<label>#{element.label}</label><input type='time' class='form-control' data-fulcrum-field-type='#{element.type}' id='#{element.key}' name='#{element.key}'>"))

  generateYesNoField: (element) ->
    buttons = "<a class='btn btn-default yes-no' data-input-id='#{element.key}' data-yes-no-val='#{element.positive.value}' role='button'>#{element.positive.label}</a><a class='btn btn-default yes-no' data-input-id='#{element.key}' data-yes-no-val='#{element.negative.value}' role='button'>#{element.negative.label}</a>"
    if element.neutral_enabled
      buttons += "<a class='btn btn-default yes-no' data-input-id='#{element.key}' data-yes-no-val='#{element.neutral.value}' role='button'>#{element.neutral.label}</a>"
    input = "<input type='hidden' id='#{element.key}' name='#{element.key}'>"
    buttons = "<div class='btn-group btn-group-justified'>#{buttons}</div>"
    panel panelBody(formGroup("<label>#{element.label}</label>#{buttons}#{input}"))

  generateHyperlinkField: (element) ->
    panel panelBody(formGroup("<label>#{element.label}</label><input type='text' class='form-control' data-fulcrum-field-type='#{element.type}' id='#{element.key}' name='#{element.key}'>"))

  generateChoiceField: (element) ->
    multiple = if element.multiple then ' multiple' else ''
    choices = []
    for choice in element.choices
      choices.push "<option value='#{choice.value}'>#{choice.label}</option>"
    choices = choices.join ''
    panel panelBody(formGroup("<label>#{element.label}</label><select class='form-control' data-fulcrum-field-type='#{element.type}' id='#{element.key}' name='#{element.key}'#{multiple}>#{choices}</select>"))
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
    parts = []
    for element in @form.form_obj.elements
      parts.push @generateElement element
    @html_content = parts.join ''

  init: ->
    @initBeforeEvents()
    @generateHTMLContent()
    @$modal_container.find('.modal-body').find('.content').html @html_content
    @$modal_container.modal()
    @initAfterEvents()

  destroy: ->
    @map.remove()
    @$modal_container.find('.modal-body').find('.content').html ''
    @$modal_container.modal 'hide'

module.exports = Creator
