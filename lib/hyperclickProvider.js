'use babel'
import { Point, Range } from 'atom';
import pathUtils from 'path';


function isRobot(textEditor){
  return textEditor.getGrammar().scopeName === 'text.robot';
}

function findKeywordAtPosition(line, column) {
  let cells = splitCells(line);
  for (let cell of Array.from(cells)) {
    let startCol = line.indexOf(cell);
    let endCol = startCol+cell.length;
    if ((column>startCol) && (column<endCol)) {
      return {
        startCol,
        endCol,
        keywordName: cell
      };
    }
  }
};

function splitCells(line){
  return line.trim().replace(/\t/, '  ').split(/\s{2,}/);
}

let autocompleteRobotProvider = undefined;

export default {
  setAutocompleteRobotProvider(service) {
    return autocompleteRobotProvider = service;
  },
  providerName: "autocomplete-robot-framework",
  getSuggestion(textEditor, point){
    let keyword;
    if (!isRobot(textEditor)) {
      return undefined;
    }
    let line = textEditor.lineTextForBufferRow(point.row);
    let keywordInfo = findKeywordAtPosition(line, point.column);
    if (!keywordInfo) {
      return undefined;
    }
    let highlightedKeywords = autocompleteRobotProvider.getKeywordsByName(keywordInfo.keywordName);
    if (highlightedKeywords.length===0) {
      return undefined;
    }

    let callback = undefined;
    if(highlightedKeywords.length===1) {
      keyword = highlightedKeywords[0];
      callback = () =>
        atom.workspace.open(keyword.resource.path, {initialLine: keyword.startRowNo, initialColumn: keyword.startColNo})
        .then(editor => editor.scrollToCursorPosition())
        .catch(error => console.log(`Error opening editor: ${error}`))
      ;
    } else {
      callback = [];
      for (keyword of Array.from(highlightedKeywords)) {
        (keyword =>
          callback.push({
            title: keyword.resource.path,
            callback() {
              return atom.workspace.open(keyword.resource.path, {initialLine: keyword.startRowNo, initialColumn: keyword.startColNo}).catch(error => console.log(`Error opening editor: ${error}`));
            }
          })
        )(keyword);
      }
    }

    return {
      range: new Range(new Point(point.row, keywordInfo.startCol), new Point(point.row, keywordInfo.endCol)),
      callback
    };
  }
};
