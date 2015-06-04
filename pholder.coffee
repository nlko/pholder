#!/usr/bin/coffee

process.on 'uncaughtException', (err) ->
  console.log('Caught exception: ')
  console.dir err

argv = require 'optimist'
      .usage 'Usage : $0 [--conf config.json] [--data datafile.json] file1 file2…'
      .alias 'c','conf'
      .alias 'd','data'
      .describe 'c','Configuration file'
      .describe 'd','A Json datafile to act as a db. (db can be contained in the config file)'
      .check (argv)-> argv.c? or argv.d?
      .argv

fs = require('fs')

lineReader = require('line-reader')

_ = require('underscore')

prepare_filename = (filename) ->
  if filename.length and filename.charAt(0) isnt "/" and filename.charAt(0) isnt "."
    filename="./"+filename
  filename

if argv.conf?
  json = require(prepare_filename argv.conf)

if argv.data?
  data = require(prepare_filename argv.data)
else
  data = json

local_json_connector = {
  init_db:->
  read_db:(config, group, template, cb)->
    if(data.hasOwnProperty group) and (data[group].hasOwnProperty template)
      cb null,data[group][template]
    else
      cb "template doesn't exist."
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

config.connector.init_db() if config.connector?init_db

extract_spaces = (str) ->
  spaces=""
  index=0
  while (index < str.length) and (str.charAt(index) is ' ' or str.charAt(index) is '\t')
    spaces+=str.charAt(index);
    index++
  spaces

String.prototype.startsWith = (prefix) ->
    @indexOf(prefix) is 0;

create_long_start = (template) -> long_start+template+long_start_end


parse_a_file = (file_to_process)->

  mode=0
  
  line_counter=0

  output_buffer=""

  add_to_output = (str) -> 
    output_buffer+="\n" unless output_buffer is ""
    output_buffer+=str

  lineReader.eachLine "file.txt", (original_line, last) ->
    line_counter++

    spaces = extract_spaces original_line
    line = original_line.trim()

    write_template = (template_str, spaces, group, template, tags_list) ->
      add_to_output (spaces + create_long_start template_str)
      code=""
      config.connector.read_db config,group,template,(err,data)->
        if err?
          console.log "$ERROR in "+file_to_process+":"+line_counter+": "+err
        else
          if _.isArray(data)
            data.forEach (elem)->
              if(code isnt "")
                code+="\n"
              code+=spaces+elem
          else
            code=spaces+data

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
      tags_list = template_str.trim().split(".")
      group = tags_list.shift()
      template = tags_list.shift()
      write_template template_str, spaces, group, template, tags_list
      else
        console.log "$ERROR in "+file_to_process+":"+line_counter+": Don't understand template "+template_str

    finalise_file = (buffer) ->
      fs.writeFile file_to_process+".tmp", buffer, (err)->
        if err?
          console.log "Failed to write", (file_to_process+".tmp")       
          console.log err
        else
          fs.rename file_to_process+".tmp", file_to_process, (err)->
            if err?
              console.log "Failed to renae", (file_to_process+".tmp") , "to " , file_to_process
              console.log err 
        #fs.renameSync('a.txt','b.txt');

    if mode is 0
      if line.startsWith short_start
        process_found_template (line.substring (short_start.length))
      else if line.startsWith long_start
        process_found_template (line.substring (long_start.length),(line.length-2))
        mode = 1
      else
        add_to_output line
    else
      if line.startsWith long_start
        mode = 0

    if (last)
      config.connector.close_db() if config.connector?init_db
      if (mode is 1)
        console.log "$ERROR line "+line_counter+": File endding unexpectedly (missing closing tag)."
      else
        finalise_file output_buffer

argv._.forEach parse_a_file
