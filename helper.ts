
import * as _ from '../node_modules/lodash'

export function stringify(data:string|string[],spaces:string){
  if(_.isArray(data)) {
    return (<string[]>data).reduce(function(acc,elem){
      if(acc != "")
        acc += '\n'
      return acc+spaces+elem
    },"")
  } else {
    return spaces+data
  }
}

export function extract_spaces(str) {
  var index, spaces;
  spaces = "";
  index = 0;
  while ((index < str.length) && (str.charAt(index) === ' ' || str.charAt(index) === '\t')) {
    spaces += str.charAt(index);
    index++;
  }
  return spaces;
};
