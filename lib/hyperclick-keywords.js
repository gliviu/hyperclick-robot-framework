'use babel'
import { Point, Range } from 'atom'
import pathUtils from 'path'
import fs from 'fs'
import common from './common'

const KEYWORD_REGEXP = /((.*)\.)?(.*)/

function findKeywordAtPosition(line, column) {
  let cells = common.splitCells(line);
  for (let cell of Array.from(cells)) {
    let startCol = line.indexOf(cell);
    let endCol = startCol+cell.length;
    if ((column>startCol) && (column<endCol)) {
      const match = KEYWORD_REGEXP.exec(cell)
      if(match){
        const prefix = match[2]
        const keywordName = match[3]
        return {
          startCol,
          endCol,
          prefix,
          keywordName
        };
      }
    }
  }
  return undefined
};

// Finds keyword within specified python library.
// Returns Result: {line: num, column: num, path: ''} if found, otherwise undefined.
function getPythonLocation(keywordName, libraryPath){
  const pythonContent = fs.readFileSync(libraryPath).toString()
  let pyInfo = {found: false, line: undefined, column: undefined}
  let lineNo = 0;
  for(const line of pythonContent.split('\n')){
    const pyKeywordName = keywordName.split(' ').join('_')
    const regexp = new RegExp(`^[ \\t]*def[ \\t]+${pyKeywordName}[ \\t]*\\(`, 'i')
    if(regexp.test(line)){
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
function getKeywordLocation(keyword, autocompleteRobotProvider){
  let resource
  if(keyword.resourceKey){
    resource = autocompleteRobotProvider.getResourceByKey(keyword.resourceKey)
  } else{
    resource = keyword.resource  // Deprecated
  }
  const isPythonLibrary = resource.isLibrary
    && resource.libraryPath
    && resource.libraryPath.toLowerCase().endsWith('.py')
  let location = undefined
  if(isPythonLibrary){
    location = getPythonLocation(keyword.name, resource.libraryPath)
  }
  return location || {
    path: resource.path,
    line: keyword.startRowNo,
    column: keyword.startColNo
  }
}

function getKeywordFromImports(keywordName, imports, autocompleteRobotProvider){
  const importedKeywords = []
  for(let importedLibrary of [...imports.libraries, {name:'BuiltIn'}]){
    const resourceKey =
      common.getResourceKey(importedLibrary.physical?importedLibrary.absolutePath:importedLibrary.name)
    importedLibrary = autocompleteRobotProvider.getResourceByKey(resourceKey)
    if(!importedLibrary){
      continue
    }
    for(const importedKeyword of importedLibrary.keywords){
      if(importedKeyword.name===keywordName){
        importedKeywords.push(importedKeyword)
        break
      }
    }
  }
  const matchingImportedResources = new Set()
  for(let importedResource of imports.resources){
    if(importedResource.resourceKey){
      // accurate import
      const resource = autocompleteRobotProvider.getResourceByKey(importedResource.resourceKey)
      if(resource){
        matchingImportedResources.add(resource)
      }
    } else{
      // approximate import
      const resourceKeys = autocompleteRobotProvider.getResourceKeys()
      for(const resourceKey of resourceKeys){
        const resource = autocompleteRobotProvider.getResourceByKey(resourceKey)
        if(resource && resource.name === importedResource.name){
          matchingImportedResources.add(resource)
        }
      }
    }
  }
  for(const importedResource of matchingImportedResources){
      for(const importedKeyword of importedResource.keywords){
        if(importedKeyword.name===keywordName){
          importedKeywords.push(importedKeyword)
          break
        }
      }
  }

  return importedKeywords
}

export default {
  getKeywordSuggestions(textEditor, point, autocompleteRobotProvider){
    // get list of matching keywords at cursor
    const line = textEditor.lineTextForBufferRow(point.row);
    const keywordInfo = findKeywordAtPosition(line, point.column);
    if (!keywordInfo) {
      return undefined;
    }

    let highlightedKeywords
    // use imports to resolve highlighted keyword
    const activeResource = common.getCurrentResource(textEditor.getPath(), autocompleteRobotProvider)
    if(activeResource){
      highlightedKeywords = getKeywordFromImports(keywordInfo.keywordName, activeResource.imports, autocompleteRobotProvider)
    }

    // disregard imports; search in all available keywords
    if(highlightedKeywords.length===0){
      highlightedKeywords = autocompleteRobotProvider.getKeywordsByName(keywordInfo.keywordName);
    }

    if (highlightedKeywords.length===0) {
      return undefined;
    }

    // build hyperclick callback
    let callback = undefined;
    if(highlightedKeywords.length===1) {
      const keyword = highlightedKeywords[0];
      callback = () => {
        const kloc = getKeywordLocation(keyword, autocompleteRobotProvider)
        atom.workspace.open(kloc.path, {initialLine: kloc.line, initialColumn: kloc.column})
        .then(editor => editor.scrollToCursorPosition())
        .catch(error => console.log(`Error opening editor: ${error}`))
      }
    } else {
      callback = [];
      for (let keyword of Array.from(highlightedKeywords)) {
        const kloc = getKeywordLocation(keyword, autocompleteRobotProvider)
        callback.push({
          title: kloc.path,
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
