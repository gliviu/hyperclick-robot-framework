{Point, Range} = require 'atom'
assert = require 'assert'
pathUtils = require 'path'

describe 'Robot Framework Hyperclick',  ->
  fixturePath = "#{__dirname}/../fixtures/gotodef"
  [editor, hyperclickProvider, autocompletePlusProvider] = []
  origOpen = atom.workspace.open
  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('language-robot-framework')
    waitsForPromise -> atom.packages.activatePackage('autocomplete-robot-framework')
    waitsForPromise -> atom.packages.activatePackage('hyperclick-robot-framework')
    runs ->
      hyperclickProvider = atom.packages.getActivePackage('hyperclick-robot-framework').mainModule.getHyperclickProvider()
      autocompletePlusProvider = atom.packages.getActivePackage('autocomplete-robot-framework').mainModule.getAutocompletePlusProvider()
    waitsForPromise -> atom.workspace.open('gotodef/testGotodef.robot')
    runs ->
      editor = atom.workspace.getActiveTextEditor()
    waitsFor ->
      return !autocompletePlusProvider.loading
    , 'Provider should finish loading', 500
    runs ->
      atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
  afterEach ->
      atom.workspace.open = origOpen
  it 'offers suggestions if clicked inside keyword', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(2, 5))
      expect(suggestion).toBeDefined()
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(2, 17))
      expect(suggestion).toBeDefined()
  it 'offers no suggestions if clicked outside keyword', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(2, 4))
      expect(suggestion).toBeUndefined()
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(2, 18))
      expect(suggestion).toBeUndefined()
  it 'offers no suggestions if keyword has no definition', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(10, 9))
      expect(suggestion).toBeUndefined()
  it 'handles keywords defined in same file', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(2, 9)) # 'test gotodef 0'
      expect(suggestion).toBeDefined()
      expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([2,4], [2, 18])))
      suggestion.callback()
      expect(atom.workspace.open).toHaveBeenCalled()
      expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("testGotodef.robot")
      assert.deepEqual(atom.workspace.open.argsForCall[0][1], {initialLine: 1, initialColumn: 0})
  it 'handles keywords defined in different file', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(3, 9)) # 'test gotodef 1'
      expect(suggestion).toBeDefined()
      expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([3,4], [3, 18])))
      suggestion.callback()
      expect(atom.workspace.open).toHaveBeenCalled()
      expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("Go To Def1.robot")
      assert.deepEqual(atom.workspace.open.argsForCall[0][1], {initialLine: 4, initialColumn: 0})
  it 'handles keyword with multiple definitions', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(7, 9))
      expect(suggestion).toBeDefined()
      expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([7,4], [7, 18])))
      expect(suggestion.callback.length).toBe(3)
      [gotodef1, gotodef2, testGotodef] = []
      for callback in suggestion.callback
        callback.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        if pathUtils.basename(atom.workspace.open.mostRecentCall.args[0]) == "Go To Def1.robot"
          assert.deepEqual(atom.workspace.open.mostRecentCall.args[1], {initialLine: 8, initialColumn: 0})
          gotodef1 = callback.title
        if pathUtils.basename(atom.workspace.open.mostRecentCall.args[0]) == "GotoDef2.robot"
          assert.deepEqual(atom.workspace.open.mostRecentCall.args[1], {initialLine: 6, initialColumn: 0})
          gotodef2 = callback.title
        if pathUtils.basename(atom.workspace.open.mostRecentCall.args[0]) == "testGotodef.robot"
          assert.deepEqual(atom.workspace.open.mostRecentCall.args[1], {initialLine: 11, initialColumn: 0})
          testGotodef = callback.title
      expect(pathUtils.normalize(gotodef1).toLowerCase()).toEqual(pathUtils.normalize("#{fixturePath}/Go To Def1.robot").toLowerCase())
      expect(pathUtils.normalize(gotodef2).toLowerCase()).toEqual(pathUtils.normalize("#{fixturePath}/GotoDef2.robot").toLowerCase())
      expect(pathUtils.normalize(testGotodef).toLowerCase()).toEqual(pathUtils.normalize("#{fixturePath}/testGotodef.robot").toLowerCase())
  it 'handles keywords defined in libdoc files', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(21, 10)) # Run Keyword If
      expect(suggestion).toBeDefined()
      expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([21,4], [21, 18])))
      suggestion.callback()
      expect(atom.workspace.open).toHaveBeenCalled()
      expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("BuiltIn.xml")
      assert.deepEqual(atom.workspace.open.argsForCall[0][1], {initialLine: 1523, initialColumn: 0})
  it 'handles multiple keywords on the same line', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(22, 6)) # Log
      expect(suggestion).toBeDefined()
      expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([22,4], [22, 7])))
      suggestion.callback()
      expect(atom.workspace.open).toHaveBeenCalled()
      expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("BuiltIn.xml")
      assert.deepEqual(atom.workspace.open.argsForCall[0][1], {initialLine: 972, initialColumn: 0})
  it 'handles multiple keywords on the same line', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(22, 17)) # Run Keyword If
      expect(suggestion).toBeDefined()
      expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([22,9], [22, 23])))
      suggestion.callback()
      expect(atom.workspace.open).toHaveBeenCalled()
      expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("BuiltIn.xml")
      assert.deepEqual(atom.workspace.open.argsForCall[0][1], {initialLine: 1523, initialColumn: 0})
  it 'handles multiple keywords on the same line', ->
    runs ->
      suggestion = hyperclickProvider.getSuggestion(editor, new Point(22, 51)) # test gotodef 3
      expect(suggestion).toBeDefined()
      expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([22,45], [22, 59])))
      suggestion.callback()
      expect(atom.workspace.open).toHaveBeenCalled()
      expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("GotoDef2.robot")
      assert.deepEqual(atom.workspace.open.argsForCall[0][1], {initialLine: 2, initialColumn: 0})
