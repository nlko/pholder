#!/usr/bin/coffee

process.on 'uncaughtException', (err) ->
  console.log('Caught exception: ')
  console.dir err

empty = ""

argv = require 'optimist'
      .usage 'Usage : $0 [--conf config.json] [--data datafile.json] [--clean] [--verbose] [--print] file1 file2…'
      .alias 'c','conf'
      .alias 'd','data'
      .describe 'c','Configuration file'
      .describe 'd','A Json datafile to act as a db. (db can be contained in the config file)'
      .describe 'clean','Remove placeholder values from files (leave empty placeholder).'      
      .describe 'print','Print result on the console'     
      .describe 'verbose','Verbose mode' 
      .boolean ['clean','print','verbose']
      .check (argv)-> argv? and (argv?.c? or argv?.d?)
      .argv

fs = require('fs')
path = require('path')

_ = require('underscore')

verbose=(str) -> console.log str if argv.verbose

prepare_filename_for_options = (filename) ->
  path.resolve filename

prepare_filename = (filename) ->
  path.resolve config_dir,filename

if argv.conf?
  json = require(prepare_filename_for_options argv.conf)
  config_dir = path.dirname(path.resolve argv.conf)
else
  config_dir = path.dirname(process.cwd())

if argv.data?
  data = require(prepare_filename_for_options argv.data)
else if json.config?.data_file?
  data = require(prepare_filename json.config.data_file)
else
  data = json

stringify = (data,spaces)->  
  if _.isArray(data)
    code=""
    data.forEach (elem)->
      if(code isnt empty)
        code+="\n"
      code+=spaces+elem
    code
  else    
    spaces+data

local_json_connector = {
  init_db:(config, data)->
  read_db:(config, context, path_list, cb)->
    val=data
    err=null
    console.dir path_list
    path_list.forEach (elem)->
      if val.hasOwnProperty elem
        val=val[elem]
      else
        err="template doesn't exist."

    cb err, (stringify val,context.spaces)

  close_db:->
}

config =
  special_char:'$'
  placeholder_short:'//'
  placeholder_long1:'/*'
  placeholder_long2:' */'
  connector:local_json_connector
  tag_indicator:'@'
  tag_separator:'.'
  path_separator:'/'


if(json?.config?)
  _.extend config,json.config

isCleanRequested = argv.clean or config.clean?

isPrintRequested = argv.print or config.print?

if _.isString config.connector
  config.connector = require(prepare_filename config.connector)

tags = {}

if config?.tagfile?
  tags = require(prepare_filename config.tagfile)

short_start=config.placeholder_short+config.special_char
long_start=config.placeholder_long1+config.special_char
long_start_end=config.placeholder_long2

config.connector.init_db config,data if config?.connector?.init_db

extract_spaces = (str) ->
  spaces=""
  index=0
  while (index < str.length) and (str.charAt(index) is ' ' or str.charAt(index) is '\t')
    spaces+=str.charAt(index);
    index++
  spaces

String.prototype.startsWith = (prefix) ->
    @indexOf(prefix) is 0;

create_short_start = (template) -> short_start+" "+template.trim()
create_long_start = (template) -> long_start+" "+template.trim()+long_start_end


parse_a_file = (file_to_process)->
  verbose "processing #{file_to_process}"

  mode=0
  
  line_counter=0

  first_outputed_line = true

  output_buffer=""

  # for each line of the file
  fs.readFileSync(file_to_process).toString().split('\n').forEach (original_line)->

    line_counter++

    spaces = extract_spaces original_line
    line = original_line.trim()

    add_to_output = (str) ->
      output_buffer+="\n" if !first_outputed_line
      first_outputed_line = false
      output_buffer+=str

    write_template = (template_str, spaces, path_list, tags_list, flags) ->
      #console.log line_counter
      #console.dir flags
      write_place_holder = (str) -> add_to_output str if (!config.remove_place_holders? or !config.remove_place_holders) and !flags.remove?
      if isCleanRequested or flags.clean?
        write_place_holder (spaces + create_short_start template_str)
      else
        write_place_holder (spaces + create_long_start template_str)
        config.connector.read_db config,{spaces:spaces},path_list, (err,code)->        
          db_object = code
          if err?
            console.log "$ERROR in "+file_to_process+":"+line_counter+": "+err
          else
            if tags_list? and _.isArray(tags_list) and tags_list.length
              reduce_func=(code, tag)->                
                func = tag.split ' '
                tag_func= func.shift()
                if func.length
                  params= func.join().split ','
                else
                  params = []                                   
                params.unshift code,path_list,db_object
                if tags.hasOwnProperty tag_func
                  code = tags[tag_func].apply(tags,params)
                  [code,new_db_object] = code if _.isArray(code)
                  db_object = new_db_object if new_db_object isnt undefined
                else
                  console.log "ERROR in "+file_to_process+":"+line_counter+": tag function ("+tag_func+") not found."
                code

              code = tags_list.reduce  reduce_func,""

            add_to_output code


        write_place_holder (spaces + create_long_start "")



    process_found_template = (template_str)->
      # A temlate can be of the form this/is/a/path@and.a.list.of.tags
      path_list = template_str.trim().split(config.tag_indicator).map (elem)->elem.trim()
      if path_list.length is 1
        tags_list=[]
      else
        tags_str = path_list.pop()
        tags_list =tags_str.trim().split(config.tag_separator).map (elem)->elem.trim()

      if path_list.length > 0
        path_part = path_list[0].trim()
        flags = if path_part.startsWith '['
          index_of_flag = path_part.indexOf ']'
          if index_of_flag is -1
            console.log "$ERROR in "+file_to_process+":"+line_counter+": missing ] in "+template_str
            null
          else
            flags_element = path_part
            path_part = path_part.substring(index_of_flag+1).trim()

            flags_element.substring(1,index_of_flag).split(',').reduce( (previous,current) ->
                index = current.indexOf '='
                if index is -1
                  previous[current.trim()] = true
                else
                  if index > 1
                    previous[current.substring(0,index).trim()] = current.substring(index+1).trim()
                  else
                    console.log "$ERROR in "+file_to_process+":"+line_counter+": unexpected , in flags of "+template_str
                previous
            , {})
        else
          {}

        if flags isnt null
          path_list = path_part.split(config.path_separator).map (elem)->elem.trim()

          write_template template_str, spaces, path_list, tags_list, flags
      else
        console.log "$ERROR in "+file_to_process+":"+line_counter+": Don't understand template "+template_str


    # if outside a template block
    if mode is 0
      if line.startsWith short_start
        process_found_template (line.substring (short_start.length))
      else if line.startsWith long_start
        process_found_template (line.substring (long_start.length),(line.length-2))
        mode = 1
      else        
        add_to_output original_line
    else
      #if inside a template block, skip all the line until the end of block mark 
      if line.startsWith long_start
        mode = 0
  #### /end of for each line



  finalise_file = (buffer) ->
    fs.writeFile file_to_process+".tmp", buffer, (err)->
      if err?
        console.log "Failed to write", (file_to_process+".tmp")       
        console.log err
      else
        fs.rename file_to_process+".tmp", file_to_process, (err)->
          if err?
            console.log "Failed to rename", (file_to_process+".tmp") , "to " , file_to_process
            console.log err 



  if (mode is 1)
    console.log "$ERROR in "+file_to_process+":"+line_counter+": File endding unexpectedly (missing closing tag)."
  else if isPrintRequested
    console.log output_buffer
  else
    finalise_file output_buffer
#### /parse_a_file

# The list of files may be provided on the command line or from the configuration file
files_to_process = 
  if config.input_files?
    (if _.isArray(config.input_files)
      config.input_files
    else
      [config.input_files]).map (file) -> prepare_filename file
  else
    argv._

#for each files from the command line or from the configuration
files_to_process.forEach (file) ->  parse_a_file file

config.connector.close_db() if config.connector?init_db
