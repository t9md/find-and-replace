{Disposable} = require 'atom'
_ = require 'underscore-plus'

module.exports =
  escapeHtml: (str) ->
    @escapeNode ?= document.createElement('div')
    @escapeNode.innerText = str
    @escapeNode.innerHTML

  escapeRegex: (str) ->
    str.replace /[.?*+^$[\]\\(){}|-]/g, (match) ->
      "\\" + match

  sanitizePattern: (pattern) ->
    pattern = @escapeHtml(pattern)
    pattern.replace(/\n/g, '\\n').replace(/\t/g, '\\t')

  getReplacementResultsMessage: ({findPattern, replacePattern, replacedPathCount, replacementCount}) ->
    if replacedPathCount
      "<span class=\"text-highlight\">Replaced <span class=\"highlight-error\">#{@sanitizePattern(findPattern)}</span> with <span class=\"highlight-success\">#{@sanitizePattern(replacePattern)}</span> #{_.pluralize(replacementCount, 'time')} in #{_.pluralize(replacedPathCount, 'file')}</span>"
    else
      "<span class=\"text-highlight\">Nothing replaced</span>"

  getSearchResultsMessage: ({findPattern, matchCount, pathCount, replacedPathCount}) ->
    if matchCount
      "#{_.pluralize(matchCount, 'result')} found in #{_.pluralize(pathCount, 'file')} for <span class=\"highlight-info\">#{@sanitizePattern(findPattern)}</span>"
    else
      "No #{if replacedPathCount? then 'more' else ''} results found for '#{@sanitizePattern(findPattern)}'"

  # options is object with following keys
  #  timeout: number (msec)
  #  class: css class
  decorationTimeout: null

  decorateRange: (editor, range, options) ->
    @decorationTimeout?.dispose()
    marker = editor.markBufferRange range,
      invalidate: options.invalidate ? 'never'
      persistent: options.persistent ? false

    editor.decorateMarker marker,
      type: 'highlight'
      class: options.class

    if options.timeout?
      timeoutID = setTimeout ->
        marker.destroy()
      , options.timeout

      @decorationTimeout = new Disposable ->
        clearTimeout(timeoutID)
        marker?.destroy()
        @decorationTimeout = null
    marker

  smartScrollToBufferPosition: (editor, point) ->
    editorElement = atom.views.getView(editor)
    editorAreaHeight = editor.getLineHeightInPixels() * (editor.getRowsPerPage() - 1)
    onePageUp = editorElement.getScrollTop() - editorAreaHeight # No need to limit to min=0
    onePageDown = editorElement.getScrollBottom() + editorAreaHeight
    target = editorElement.pixelPositionForBufferPosition(point).top

    center = (onePageDown < target) or (target < onePageUp)
    editor.scrollToBufferPosition(point, {center})
