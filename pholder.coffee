#!/usr/bin/coffee

process.on 'uncaughtException', (err) ->
  console.log('Caught exception: ')
  console.dir err

empty = ""

argv = require 'optimist'
      .usage 'Usage : $0 [--conf config.json] [--data datafile.json] file1 file2…'
      .alias 'c','conf'
      .alias 'd','data'
      .describe 'c','Configuration file'
      .describe 'd','A Json datafile to act as a db. (db can be contained in the config file)'
      .check (argv)-> argv? and (argv?.c? or argv?.d?)
      .argv

fs = require('fs')
path = require('path')

_ = require('underscore')

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

if(json?.config?)
  _.extend config,json.config

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

create_long_start = (template) -> long_start+" "+template.trim()+long_start_end


parse_a_file = (file_to_process)->

  mode=0
  
  line_counter=0

  first_outputed_line = true

  output_buffer=""

  fs.readFileSync(file_to_process).toString().split('\n').forEach (original_line)->

    add_to_output = (str) ->
      output_buffer+="\n" if !first_outputed_line
      first_outputed_line = false
      output_buffer+=str

    line_counter++

    spaces = extract_spaces original_line
    line = original_line.trim()

    write_template = (template_str, spaces, path_list, tags_list) ->
      add_to_output (spaces + create_long_start template_str)
      config.connector.read_db config,{spaces:spaces},path_list, (err,code)->        
        if err?
          console.log "$ERROR in "+file_to_process+":"+line_counter+": "+err
        else 
          if tags_list? and _.isArray(tags_list)
            reduce_func=(code, tag)->
              if tags.hasOwnProperty tag
                code= (tags[tag](code))
              else
                console.log "$ERROR in "+file_to_process+":"+line_counter+": tag function("+tag+") not found."
              code

            code = tags_list.reduce  reduce_func,code

          add_to_output code


      add_to_output (spaces + create_long_start "")

    process_found_template = (template_str)->
      path_list = template_str.trim().split("@")
      if path_list.length is 1
        tags_list=[]
      else
        tags_str = path_list.pop()
        tags_list =tags_str.trim().split(".")
      if path_list.length > 0
        path_list = path_list[0].split("/")

        write_template template_str, spaces, path_list, tags_list
      else
        console.log "$ERROR in "+file_to_process+":"+line_counter+": Don't understand template "+template_str

    if mode is 0
      if line.startsWith short_start
        process_found_template (line.substring (short_start.length))
      else if line.startsWith long_start
        process_found_template (line.substring (long_start.length),(line.length-2))
        mode = 1
      else        
        add_to_output original_line        
    else
      if line.startsWith long_start
        mode = 0

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
  else
    finalise_file output_buffer

argv._.forEach parse_a_file

config.connector.close_db() if config.connector?init_db
