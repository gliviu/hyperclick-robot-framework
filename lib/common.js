'use babel'
import pathUtils from 'path'

export default {
  splitCells(line){
    return line.trim().replace(/[ ]{2,}/g, '\t').split(/\t+/);
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

  // ,
  // buildResourcesByName(autocompleteRobotProvider){
  //   const resourcesByName = new Map()
  //   for(const resourceKey of resourceKeys){
  //     const resource = autocompleteRobotProvider.getResourceByKey(resourceKey)
  //     let reslist = resourcesByName.get(resource.name)
  //     if(!reslist){
  //       reslist = []
  //       resourcesByName.set(resource.name, reslist)
  //     }
  //     reslist.push(resource)
  //   }
  //
  // }

}
