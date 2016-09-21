module.exports =
    # command example
    # socket / accept @ filter ( test_filter1 , test_filter2 ) .  decl
    # the path in db is socket/accept
    # the function to apply is filter(test_filter1 , test_filter2) and decl on the result

    # example can be launched with the following command :
    # ./pholder.coffee -c config.json file.txt

    # data value can be changed in the config.json file

    # str : previously processed (result of previous piped commmand or "")
    # path : the object path
    # obj : the object in the db
    # params : the list of parameters passed to the command
    debug:(str,path,obj,param1,param2)->
      console.dir str
      console.dir path
      console.dir obj

    #this command add a semicolon to a previously piped command or to the object
    decl:(str,path,obj,param1,param2)->
      if str is ""
        obj+";"
      else
        str+";"

    # this command trim the passed object.
    trim:(str,path,obj)-> obj.trim()

    # this command concat the two fields of the passed object
    filter:(str,path,obj,param1,param2)->
        obj[param1]+obj[param2]
