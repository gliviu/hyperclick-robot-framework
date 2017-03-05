'use babel'
import hyperclickProvider from './hyperclickProvider'

export default {
  activate() {
    const lrf = atom.packages.resolvePackagePath('language-robot-framework')
    const arf = atom.packages.resolvePackagePath('autocomplete-robot-framework')
    const hpc = atom.packages.resolvePackagePath('hyperclick')
    if(!lrf || !arf || !hpc){
      require('atom-package-deps').install('hyperclick-robot-framework', true)
      .catch((error) => {
        console.error(`Error occurred while installing dependencies: ${error.stack ? error.stack : error}`);
      })
    }
  },
  getAutocompleteRobotProvider(service) {
    return hyperclickProvider.setAutocompleteRobotProvider(service);
  },
  getHyperclickProvider() { return hyperclickProvider; }
};
