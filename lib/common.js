'use babel'
import pathUtils from 'path'

export default {
  getResourceKey(resourcePath){
    return pathUtils.normalize(resourcePath).toLowerCase();
  },
  splitCells(line){
    return this.normalizeLine(line).split(/\t+/);
  },
  normalizeLine(line){
    return line.trim().replace(/[ ]{2,}/g, '\t')
  },
  getCurrentResource(path, autocompleteRobotProvider){
    // support for deprecated consumer API.
    if(typeof autocompleteRobotProvider.getResourceKeys === 'undefined') return undefined

    path = pathUtils.normalize(path)
    for(const resourceKey of autocompleteRobotProvider.getResourceKeys()){
      const resource = autocompleteRobotProvider.getResourceByKey(resourceKey)
      if(resource && path===resource.path){
        return resource
      }
    }
    return undefined
  }

}
