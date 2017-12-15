{Point, Range} = require 'atom'
assert = require 'assert'
pathUtils = require 'path'

TIMEOUT=5000
SEP = pathUtils.sep

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
    waitsFor ->
      return !autocompletePlusProvider.loading
    , 'Provider should finish loading', TIMEOUT
  afterEach ->
      atom.workspace.open = origOpen
  describe 'Test hyperclick opens new editor',  ->
    origOpen = atom.workspace.open
    beforeEach ->
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
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
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(7, 9))  # test gotodef 5
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
        expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("BuiltIn.py")
        expect(atom.workspace.open.argsForCall[0][1].initialLine).toBeGreaterThan(0)
        expect(atom.workspace.open.argsForCall[0][1].initialColumn).toEqual(0)
    it 'handles multiple keywords on the same line', ->
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(22, 6)) # Log
        expect(suggestion).toBeDefined()
        expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([22,4], [22, 7])))
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("BuiltIn.py")
        expect(atom.workspace.open.argsForCall[0][1].initialLine).toBeGreaterThan(0)
        expect(atom.workspace.open.argsForCall[0][1].initialColumn).toEqual(0)
    it 'handles multiple keywords on the same line', ->
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(22, 17)) # Run Keyword If
        expect(suggestion).toBeDefined()
        expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([22,9], [22, 23])))
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("BuiltIn.py")
        expect(atom.workspace.open.argsForCall[0][1].initialLine).toBeGreaterThan(0)
        expect(atom.workspace.open.argsForCall[0][1].initialColumn).toEqual(0)
    it 'handles multiple keywords on the same line', ->
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(22, 51)) # log -> Run Keyword If -> test gotodef 3
        expect(suggestion).toBeDefined()
        expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([22,45], [22, 59])))
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("GotoDef2.robot")
        assert.deepEqual(atom.workspace.open.argsForCall[0][1], {initialLine: 2, initialColumn: 0})
    it 'handles keyword prefixed with resource', ->
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(23, 10)) # GotoDef2.test gotodef 3
        expect(suggestion).toBeDefined()
        expect(JSON.stringify(suggestion.range)).toEqual(JSON.stringify(new Range([23,4], [23, 27])))
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        expect(pathUtils.basename(atom.workspace.open.argsForCall[0][0])).toBe("GotoDef2.robot")
        assert.deepEqual(atom.workspace.open.argsForCall[0][1], {initialLine: 2, initialColumn: 0})
  describe 'Approximate import resolution',  ->
    it 'proposes only suggestions from imported libraries - one import', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t1.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(13, 5))  # Impkw
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t2.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(12, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
    it 'proposes only suggestions from imported libraries - multiple imports', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t3.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(17, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
        expect(suggestion.callback.length).toEqual(2)
    it 'proposes all suggestions when no import library is found', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t4.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(9, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
        expect(suggestion.callback.length).toEqual(3)
    it 'proposes only suggestions from imported resources - one import', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t1.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(14, 5)) # impkwx
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t2.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(13, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
    it 'proposes only suggestions from imported resources - multiple imports', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t3.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(18, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
        expect(suggestion.callback.length).toEqual(2)
    it 'proposes all suggestions when no import resource is found', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t4.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(10, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
        expect(suggestion.callback.length).toEqual(3)
    it 'proposes all suggestions from resources with same name, disregarding imports', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t1.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(15, 5))  # impkwy
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
        expect(suggestion.callback.length).toEqual(2)
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t2.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(14, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
        expect(suggestion.callback.length).toEqual(2)
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t3.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(19, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
        expect(suggestion.callback.length).toEqual(2)
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t4.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(11, 5))
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
        expect(suggestion.callback.length).toEqual(2)
  describe 'Accurate import resolution',  ->
    it 'proposes one suggestion when single import is determined', ->
      waitsForPromise -> atom.workspace.open('gotodef/accurate-resource-imports/t1.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(15, 5))  # aci1kw
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        path = atom.workspace.open.argsForCall[0][0]
        expect(path.endsWith("0#{SEP}aci1.robot")).toBeTruthy()
    it 'proposes multiple suggestions if multiple imports resolved', ->
      waitsForPromise -> atom.workspace.open('gotodef/accurate-resource-imports/t2.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(16, 5))  # aci1kw
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
    it 'suggests relative import in same directory', ->
      waitsForPromise -> atom.workspace.open('gotodef/accurate-resource-imports/t1.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(16, 5))  # aci2kw
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        path = atom.workspace.open.argsForCall[0][0]
        expect(path.endsWith("accurate-resource-imports#{SEP}aci2.robot")).toBeTruthy()
    it 'suggests relative import in diffrent directory', ->
      waitsForPromise -> atom.workspace.open('gotodef/accurate-resource-imports/t2.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(17, 5))  # aci2kw
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        path = atom.workspace.open.argsForCall[0][0]
        expect(path.endsWith("1#{SEP}aci2.robot")).toBeTruthy()
  describe 'Hyperclick into imported resources',  ->
    it 'suggests accurate relative import in different directory', ->
      waitsForPromise -> atom.workspace.open('gotodef/accurate-resource-imports/t1.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(1, 15))  # 0/aci1.robot
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        path = atom.workspace.open.argsForCall[0][0]
        expect(path.endsWith("0#{SEP}aci1.robot")).toBeTruthy()
    it 'suggests accurate relative import in same directory', ->
      waitsForPromise -> atom.workspace.open('gotodef/accurate-resource-imports/t1.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(2, 15))  # aci2.robot
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        path = atom.workspace.open.argsForCall[0][0]
        expect(path.endsWith("accurate-resource-imports#{SEP}aci2.robot")).toBeTruthy()
    it 'suggests single approximate import', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t1.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(2, 15))  # ${1}/kw1.robot
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        path = atom.workspace.open.argsForCall[0][0]
        expect(path.endsWith("1#{SEP}kw1.robot")).toBeTruthy()
    it 'suggests multiple approximate imports', ->
      waitsForPromise -> atom.workspace.open('gotodef/approximate-resource-imports/t1.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(3, 15))  # ${1}/kw4.robot
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeTruthy()
  describe 'Hyperclick into imported libraries',  ->
    it 'suggests imported python library', ->
      waitsForPromise -> atom.workspace.open('gotodef/library-imports/libimp1.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(1, 15))  # Collections
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        path = atom.workspace.open.argsForCall[0][0]
        expect(path.endsWith('Collections.py')).toBeTruthy()
    it 'suggests imported libdoc library', ->
      waitsForPromise -> atom.workspace.open('gotodef/library-imports/libimp1.robot')
      runs -> editor = atom.workspace.getActiveTextEditor()
      runs -> atom.workspace.open = jasmine.createSpy("atom.workspace.open() spy").andReturn(Promise.resolve())
      runs ->
        suggestion = hyperclickProvider.getSuggestion(editor, new Point(2, 15))  # LibdocLib
        expect(suggestion).toBeDefined()
        expect(Array.isArray(suggestion.callback)).toBeFalsy()
        suggestion.callback()
        expect(atom.workspace.open).toHaveBeenCalled()
        path = atom.workspace.open.argsForCall[0][0]
        expect(path.endsWith('LibdocLib.xml')).toBeTruthy()
