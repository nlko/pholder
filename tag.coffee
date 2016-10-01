module.exports =
    # command example
    # socket / accept @ filter ( test_filter1 , test_filter2 ) .  decl
    # the path in db is socket/accept
    # the function to apply is filter(test_filter1 , test_filter2) and decl on the result

    # example can be launched with the following command :
    # ./pholder.coffee -c config.json file.txt

    # data value can be changed in the config.json file

    # str : previously processed (result of previous piped commmand or "")
    # obj : the object in the db
    # meta : a metadata object containing:
    # * path : the object path
    # * param : the array of parameters passed to the command
    debug:(str,obj,meta)->
      console.dir str
      console.dir obj
      console.dir meta

    #this command add a semicolon to a previously piped command or to the object
    decl:(str,obj,meta)->
      if str is ""
        obj+";"
       else
        str+";"

    # this command trim the passed object.
    trim:(str,obj)-> obj.trim()

    # this command concat the two fields of the passed object
    filter:(str,obj,meta)->
        obj[meta.param[0]]+obj[meta.param[1]]

    # indexed access to array object
    at:(str,obj,meta)->
        @debug str,obj,meta
        obj[meta.param[0]]
