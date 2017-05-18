'use babel'
import { Point, Range } from 'atom'
import common from './common'
import pathUtils from 'path'

var libraryRegexp = /(Library\t)([^\t$]*).*/i;

function findImportAtPosition(line, column){
  normalizeLine = common.normalizeLine(line)
  const match = libraryRegexp.exec(normalizeLine)
  if(match){
    const library = match[2]
    const startCol = line.indexOf(library)
    const endCol = startCol+library.length;
    if ((column>startCol) && (column<endCol)) {
      let name, path, physical;
      if(library.toLowerCase().endsWith('.py')){
        path = library
        physical = true
      } else{
        name = library
        physical = false
      }
      return {
        startCol, endCol,
        name, path, physical
      };
    }
  }
  return undefined
}


export default {
  getKeywordSuggestions(textEditor, point, autocompleteRobotProvider){
    const line = textEditor.lineTextForBufferRow(point.row);
    const importInfo = findImportAtPosition(line, point.column)
    if(importInfo===undefined){
      return undefined
    }

    let resource = undefined

    if(importInfo.physical){
      // physical path library
      const activeResource = common.getCurrentResource(textEditor.getPath(), autocompleteRobotProvider)
      if(activeResource){
        for(const importedLibrary of activeResource.imports.libraries){
          if(importedLibrary.path && importedLibrary.path===importInfo.path){
            const resourceKey = common.getResourceKey(importedLibrary.absolutePath)
            if(resourceKey){
              resource = autocompleteRobotProvider.getResourceByKey(resourceKey)
            }
            break
          }
        }
      }
    } else{
      // normal library
      resource = autocompleteRobotProvider.getResourceByKey(importInfo.name.toLowerCase())
    }
    if(!resource){
      return undefined;
    }

    // build hyperclick callback
    const callback = () => {
      atom.workspace.open(resource.libraryPath || resource.path, {initialLine: 0, initialColumn: 0})
      .then(editor => editor.scrollToCursorPosition())
      .catch(error => console.log(`Error opening editor: ${error}`))
    }

    return {
      range: new Range(new Point(point.row, importInfo.startCol), new Point(point.row, importInfo.endCol)),
      callback
    };
  }
}
