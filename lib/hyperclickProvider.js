'use babel'
import { Point, Range } from 'atom'
import pathUtils from 'path'
import fs from 'fs'


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

// Finds keyword within specified python library.
// Returns Result: {line: num, column: num, path: ''} if found, otherwise undefined.
function getPythonLocation(keywordName, libraryPath){
  const pythonContent = fs.readFileSync(libraryPath).toString()
  let pyInfo = {found: false, line: undefined, column: undefined}
  let lineNo = 0;
  for(const line of pythonContent.split('\n')){
    const kwName = keywordName.split(' ').join('_').toLowerCase()
    if(line.trim().toLowerCase().startsWith(`def ${kwName}`)){
      pyInfo.found = true
      pyInfo.line = lineNo
      pyInfo.column = 0
      break
    }
    lineNo++
  }
  if(pyInfo.found) {
    return {
      path: libraryPath,
      line: pyInfo.line,
      column: pyInfo.column
    }
  } else {
    return undefined
  }
}

// Returns location of the keyword.
// Result: {line: num, column: num, path: ''}
function getKeywordLocation(keyword){
  const isPythonLibrary = keyword.resource.isLibrary
    && keyword.resource.libraryPath
    && keyword.resource.libraryPath.toLowerCase().endsWith('.py')
  let location = undefined
  if(isPythonLibrary){
    location = getPythonLocation(keyword.name, keyword.resource.libraryPath)
  }
  return location || {
    path: keyword.resource.path,
    line: keyword.startRowNo,
    column: keyword.startColNo
  }
}

let autocompleteRobotProvider = undefined;

export default {
  providerName: "autocomplete-robot-framework",
  setAutocompleteRobotProvider(service) {
    autocompleteRobotProvider = service;
  },
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
      callback = () => {
        const kloc = getKeywordLocation(keyword)
        atom.workspace.open(kloc.path, {initialLine: kloc.line, initialColumn: kloc.column})
        .then(editor => editor.scrollToCursorPosition())
        .catch(error => console.log(`Error opening editor: ${error}`))
      }
    } else {
      callback = [];
      for (let keyword of Array.from(highlightedKeywords)) {
        const kloc = getKeywordLocation(keyword)
        callback.push({
          title: keyword.resource.path,
          callback() {
            atom.workspace.open(kloc.path, {initialLine: kloc.line, initialColumn: kloc.column})
            .then(editor => editor.scrollToCursorPosition())
            .catch(error => console.log(`Error opening editor: ${error}`))
          }
        })
      }
    }

    return {
      range: new Range(new Point(point.row, keywordInfo.startCol), new Point(point.row, keywordInfo.endCol)),
      callback
    };
  }
};
