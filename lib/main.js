'use babel'
import hyperclickProvider from './hyperclickProvider'

export default {
  activate() {
    require('atom-package-deps').install('hyperclick-robot-framework', true)
    .catch((error) => {
      console.error(`Error occurred while installing dependencies: ${error.stack ? error.stack : error}`);
    })
  },
  getAutocompleteRobotConsumer(service) {
    return hyperclickProvider.setAutocompleteRobotProvider(service);
  },
  getHyperclickProvider() { return hyperclickProvider; }
};
