'use babel'
import pathUtils from 'path'

export default {
  splitCells(line){
    return line.trim().replace(/[ ]{2,}/g, '\t').split(/\t+/);
  },
  getCurrentResource(path, autocompleteRobotProvider){
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
