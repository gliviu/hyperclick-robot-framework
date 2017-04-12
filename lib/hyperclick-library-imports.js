'use babel'
import { Point, Range } from 'atom'
import common from './common'

function findImportAtPosition(line, column){
  const cells = common.splitCells(line);
  if(cells.length>=2 && cells[0].toLowerCase()==='library'){
    const name = cells[1]
    const startCol = line.indexOf(name);
    const endCol = startCol+name.length;
    if ((column>startCol) && (column<endCol)) {
      return {
        startCol,
        endCol,
        name,
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


    const resource = autocompleteRobotProvider.getResourceByKey(importInfo.name.toLowerCase())
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
