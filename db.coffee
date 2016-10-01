local_data={}

_ = require 'underscore'

stringify = (data,spaces)->
  if _.isArray(data)
    code=""
    data.forEach (elem)->
      if(code isnt "")
        code+="\n"
      code+=spaces+elem
    code
  else
    spaces+data

module.exports =
  init_db:(config, data)->
    local_data = data

  #read_db:(config, group, template, cb)->
  #  if(local_data.hasOwnProperty group) and (local_data[group].hasOwnProperty template)
  #    cb null, local_data[group][template]
  #  else
  #    cb ("Template not found for "+group+"/"+template)


  read_db:(config, context, path_list, cb)->
    val=local_data
    err=null
    path_list.forEach (elem)->
      if val.hasOwnProperty elem
        val=val[elem]
      else
        err="template doesn't exist."

    if (_.isObject val) and (_.isArray val)
      cb err, val
    else
      cb err, (stringify val,context.spaces)
