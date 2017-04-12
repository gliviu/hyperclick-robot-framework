'use babel'
import { Point, Range } from 'atom'
import pathUtils from 'path'
import fs from 'fs'
import common from './common'

function findImportAtPosition(line, column){
  const cells = common.splitCells(line);
  if(cells.length>=2 && cells[0].toLowerCase()==='resource'){
    const path = cells[1]
    const startCol = line.indexOf(path);
    const endCol = startCol+path.length;
    const extension = pathUtils.extname(path)
    const name = pathUtils.basename(path, extension)
    if ((column>startCol) && (column<endCol)) {
      return {
        startCol,
        endCol,
        path,
        name,
        extension
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

    const matchingImportedResources = new Set()

    // accurate import
    const activeResource = common.getCurrentResource(textEditor.getPath(), autocompleteRobotProvider)
    if(activeResource){
      for(const importedResource of activeResource.imports.resources){
        if(importedResource.path===importInfo.path){
          if(importedResource.resourceKey){
            const resource = autocompleteRobotProvider.getResourceByKey(importedResource.resourceKey)
            if(resource){
              matchingImportedResources.add(resource)
            }
          }
          break
        }
      }
    }

    if(matchingImportedResources.size===0){
      // approximate import
      const resourceKeys = autocompleteRobotProvider.getResourceKeys()
      for(const resourceKey of resourceKeys){
        const resource = autocompleteRobotProvider.getResourceByKey(resourceKey)
        if(resource && resource.name === importInfo.name && resource.extension === importInfo.extension){
          matchingImportedResources.add(resource)
        }
      }
    }

    if (matchingImportedResources.size===0) {
      return undefined;
    }

    // build hyperclick callback
    let callback = undefined;
    if(matchingImportedResources.size===1) {
      const resource = Array.from(matchingImportedResources)[0]
      callback = () => {
        atom.workspace.open(resource.path, {initialLine: 0, initialColumn: 0})
        .then(editor => editor.scrollToCursorPosition())
        .catch(error => console.log(`Error opening editor: ${error}`))
      }
    } else {
      callback = [];
      for (const resource of Array.from(matchingImportedResources)) {
        callback.push({
          title: resource.path,
          callback() {
            atom.workspace.open(resource.path, {initialLine: 0, initialColumn: 0})
            .then(editor => editor.scrollToCursorPosition())
            .catch(error => console.log(`Error opening editor: ${error}`))
          }
        })
      }
    }

    return {
      range: new Range(new Point(point.row, importInfo.startCol), new Point(point.row, importInfo.endCol)),
      callback
    };
  }
}
