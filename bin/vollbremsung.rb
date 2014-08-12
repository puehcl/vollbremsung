#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

require 'optparse'
require 'mkmf' # part of stdlib
require 'open3'
require 'json'

def log(msg)
  puts $time.strftime("%Y-%m-%d %H:%M:%S") +  " #{msg}"
end

def probe(file)
  stdout,stderr,status = Open3.capture3("ffprobe -v quiet -print_format json -show_format -show_streams \"#{file}\"")
  if status.success?
    return JSON.parse(stdout)
  else
    STDERR.puts stderr
    return nil
  end
end

if __FILE__ == $0

  USAGE = "Usage: vollbremsung [options] <target_directory>"
  
  options = {}
  begin 
    OptionParser.new do |opts|
      opts.banner = USAGE
      opts.separator ""

      opts.on("-d", "--delete", "Delete source files after successful encoding") do |flag|
        options[:delete]  = true
      end
      opts.separator ""
    
      opts.on("-r", "--rename", "Rename source files to <FILENAME>.old after successful encoding") do |flag|
        options[:rename] = true
      end
      opts.separator ""
      
      opts.on("-t", "--title", "Set the mp4 title to the filename") do |flag|
        options[:title] = true
      end
      opts.separator ""
    
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
      opts.separator ""
    end.parse! # do the parsing. do it now!
  rescue
    puts "Option parsing not supported on your system. All options will be ignored."
    puts "To enable support run 'gem install optparse'"
    options[:delete] = false
    options[:rename] = false
  end


  if ARGV[0].nil? 
    puts "No target directory provided."
    puts USAGE
    exit 1
  end
  
  TARGET_DIR_PATH = ARGV[0]
  
  unless File.exists?(TARGET_DIR_PATH)
    puts "The target path you provided does not exists."
    exit 1
  end
  
  unless File.directory?(TARGET_DIR_PATH)
    puts "The target path you provided is not a directory."
    exit 1
  end
  
  unless find_executable('HandbrakeCLI') 
    unless find_executable('HandBrakeCLI')
      puts "It seems you do not have HandbrakeCLI installed or it is not available in your $PATH."
      puts "Install it an run again"
      exit 1
    else
      HANDBRAKE_CLI = "HandBrakeCLI" # this is the FreeBSD version
    end
  else
    HANDBRAKE_CLI = "HandbrakeCLI" # OSX version
  end
  
  unless find_executable 'ffprobe'
    puts "It seems you do not have ffprobe installed or it is not available in your $PATH."
    puts "ffprobe is part of ffmpeg. Install it for your system and run again."
    exit 1
  end
  
  $time = Time.new
  CONVERT_TYPES = ['mkv','avi','mov','flv','mpg','wmv']
  HANDBRAKE_OPTIONS="--encoder x264 --quality 20.0 --aencode faac -B 160 --mixdown dpl2 --arate Auto -D 0.0 --format mp4 --markers --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 --x264-preset veryfast --loose-anamorphic --modulus 2"
  
  src_files = []
  
  Dir.entries(TARGET_DIR_PATH).each do |file|
    if CONVERT_TYPES.include?(File.extname(file).downcase[1..-1])
      src_files << file
    end
  end
  
  log "Files found:"
  src_files.each do |file|
    puts "* #{file}"
  end

  Dir.chdir(TARGET_DIR_PATH)
  
  src_files.each do |infile|
    
    metadata = probe(infile)
    if metadata.nil?
      log "ERROR retrieving metadata -- skipping this file"
      next
    end
    
    StreamStruct = Struct.new(:count,:names)
    astreams = StreamStruct.new(0,[]) # audio streams
    sstreams = StreamStruct.new(0,[]) # subtitle streams
    
    metadata['streams'].each do |stream|
      case stream['codec_type']
      when 'audio'  
        astreams.count += 1
        astreams.names << stream['tags']['title']
      when 'subtitle' 
        sstreams.count += 1
        sstreams.names << stream['tags']['title']
      else 
        # this is attachment stuff, like typefonts --> ignore
      end
    end

    filename = File.basename(infile, File.extname(infile)) # without ext
    outfile = "#{filename}.mp4"
    
    log "#{infile} --> #{outfile}"
    
    #puts "#{HANDBRAKE_CLI} #{HANDBRAKE_OPTIONS} --audio #{(1..astreams.count).to_a.join(',')} --aname #{astreams.names.join(',')} --subtitle #{(1..sstreams.count).to_a.join(',')} -i \"#{infile}\" -o \"#{outfile}\" 2>&1"
    
    %x( #{HANDBRAKE_CLI} #{HANDBRAKE_OPTIONS} --audio #{(1..astreams.count).to_a.join(',')} --aname #{astreams.names.join(',')} --subtitle #{(1..sstreams.count).to_a.join(',')} -i \"#{infile}\" -o \"#{outfile}\" 2>&1 )
    
    if $?.exitstatus == 0
      log "SUCCESS: encoding done"
      
      if options[:rename]
        log "renaming #{infile} to .old"
        File.rename infile, "#{infile}.old" 
      end
      
      if options[:title]
        log "setting mp4 title"
        puts "ffmpeg -i \"#{outfile}\" -metadata title=\"#{filename}\"  -acodec copy -vcodec copy -scodec copy \"#{outfile}.neu\""
        %x( ffmpeg -i \"#{outfile}\" -metadata title=\"#{filename}\"  -acodec copy -vcodec copy -scodec copy \"#{outfile}.neu\" )
         if $?.exitstatus == 0
           begin
             File.delete outfile
             File.rename "#{outfile}.neu", outfile 
           rescue
             log "ERROR: moving #{outfile}.neu to #{outfile}"
           end
         else
           log "ERROR: it seems the mp4 title could not be changed"
         end
      end
    
    else 
      log "ERROR: Handbrake exited with an error"
    end
    log "" # just to make output prettier
  end
  
  log "conversion list FINISHED"

end