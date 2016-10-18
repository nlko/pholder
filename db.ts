let local_data={}

import * as _ from '../node_modules/lodash'

import * as helper from './helper'

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
    return cb(err, helper.stringify(val, context.spaces));
  }
}
