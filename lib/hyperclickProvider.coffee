{Point,Range} = require 'atom'
# keywordsRepo = require('./keywords')
pathUtils = require('path')


isRobot = (textEditor) ->
  return textEditor.getGrammar().scopeName == 'text.robot'

findKeywordAtPosition = (line, column) ->
  cells = splitCells(line)
  for cell in cells
    startCol = line.indexOf(cell)
    endCol = startCol+cell.length
    if column>startCol && column<endCol
      return {
        startCol: startCol,
        endCol: endCol,
        keywordName: cell
      }

splitCells = (line) ->
  line.trim().replace(/\t/, '  ').split(/\s{2,}/)

autocompleteRobotProvider = undefined

module.exports =
  setAutocompleteRobotProvider: (service) ->
    autocompleteRobotProvider = service
  providerName: "autocomplete-robot-framework"
  getSuggestion : (textEditor, point)->
    if !isRobot(textEditor)
      return undefined
    line = textEditor.lineTextForBufferRow(point.row)
    keywordInfo = findKeywordAtPosition(line, point.column)
    if !keywordInfo
      return undefined
    highlightedKeywords = autocompleteRobotProvider.getKeywordsByName(keywordInfo.keywordName)
    if highlightedKeywords.length==0
      return undefined

    callback = undefined
    if(highlightedKeywords.length==1)
      keyword = highlightedKeywords[0]
      callback = ->
        atom.workspace.open(keyword.resource.path, {initialLine: keyword.startRowNo, initialColumn: keyword.startColNo})
        .then (editor) -> 
          editor.scrollToCursorPosition()
        .catch (error) ->
          console.log "Error opening editor: #{error}"
    else
      callback = []
      for keyword in highlightedKeywords
        do(keyword) ->
          callback.push {
            title: keyword.resource.path
            callback: ->
              atom.workspace.open(keyword.resource.path, {initialLine: keyword.startRowNo, initialColumn: keyword.startColNo}).catch (error) ->
                console.log "Error opening editor: #{error}"
          }

    return {
      range: new Range(new Point(point.row, keywordInfo.startCol), new Point(point.row, keywordInfo.endCol)),
      callback: callback
    }
