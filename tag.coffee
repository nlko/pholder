module.exports =
    decl:(str)-> str+";"
    trim:(str)-> str.trim()
    filter:(str,path,obj,param1,param2)->
        obj[param1]+obj[param2]
