'use babel'
import { Point, Range } from 'atom'
import pathUtils from 'path'
import fs from 'fs'
import hyperclickKeywords from './hyperclick-keywords'
import hyperclickResourceImports from './hyperclick-resource-imports'
import hyperclickLibraryImports from './hyperclick-library-imports'

let autocompleteRobotProvider = undefined;

function isRobot(textEditor){
  return textEditor.getGrammar().scopeName === 'text.robot';
}

export default {
  providerName: "autocomplete-robot-framework",
  setAutocompleteRobotProvider(service) {
    autocompleteRobotProvider = service;
  },
  getSuggestion(textEditor, point){
    if (!isRobot(textEditor)) {
      return undefined;
    }

    const libraryImportSuggestions = hyperclickLibraryImports.getKeywordSuggestions(textEditor, point, autocompleteRobotProvider)
    if(libraryImportSuggestions){
      return libraryImportSuggestions
    }
    const resourceImportSuggestions = hyperclickResourceImports.getKeywordSuggestions(textEditor, point, autocompleteRobotProvider)
    if(resourceImportSuggestions){
      return resourceImportSuggestions
    }
    return hyperclickKeywords.getKeywordSuggestions(textEditor, point, autocompleteRobotProvider)
  }
};
