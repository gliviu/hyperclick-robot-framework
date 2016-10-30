hyperclickProvider = require './hyperclickProvider'
module.exports =
  getAutocompleteRobotConsumer: (service) -> 
    hyperclickProvider.setAutocompleteRobotProvider(service)
  getHyperclickProvider: -> hyperclickProvider
