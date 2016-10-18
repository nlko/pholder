let local_data={}

import * as _ from '../node_modules/lodash'

let stringify = function (data:string|string[],spaces:string){
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

export function init_db(config,data):void {
  local_data = data
}

export function read_db(config, context, path_list, cb) {
  var err, val;
  val = local_data;
  err = null;
  path_list.forEach(function(elem) {
    if (val.hasOwnProperty(elem)) {
      return val = val[elem];
    } else {
      return err = "template doesn't exist. (" + path_list + ")";
    }
  });
  if ((_.isObject(val)) && (_.isArray(val))) {
    return cb(err, val);
  } else {
    return cb(err, stringify(val, context.spaces));
  }
}
