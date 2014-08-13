#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

require 'mkmf' # part of stdlib
require 'open3'
require 'json'
require 'handbrake'

def log(msg)
  puts Time.new.strftime("%Y-%m-%d %H:%M:%S") +  " #{msg}"
end

def ffprobe(file)
  stdout,stderr,status = Open3.capture3("ffprobe -v quiet -print_format json -show_format -show_streams \"#{file}\"")
  if status.success?
    return JSON.parse(stdout)
  else
    STDERR.puts stderr
    return nil
  end
end

if __FILE__ == $0

  USAGE = "Usage: vollbremsung [options] <target>"
  
  options = {}
  begin 
    require 'optparse'
    OptionParser.new do |opts|
      opts.banner = USAGE
      opts.separator ""

      opts.on("-d", "--delete", "Delete source files after successful encoding") do |flag|
        options[:delete]  = true
      end
      opts.separator ""
    
      opts.on("-m", "--move", "Move source files to <FILENAME>.old after successful encoding") do |flag|
        options[:move] = true
      end
      opts.separator ""
      
      opts.on("-r", "--recursive", "Process all file in subdirectories recursively as well") do |flag|
        options[:recursive] = true
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
  rescue LoadError
    puts "Option parsing not supported on your system. All options will be ignored."
    puts "To enable support run 'gem install optparse'"
    options[:delete] = false
    options[:move] = false
    options[:recursive] = false
    options[:title] = false
  end


  if ARGV[0].nil? 
    puts "No target directory provided."
    puts USAGE
    exit 1
  end
  
  TARGET_PATH = ARGV[0]
  
  unless File.exists?(TARGET_PATH)
    puts "The target path you provided does not exists."
    exit 1
  end
  
  unless find_executable('HandbrakeCLI') || find_executable('HandBrakeCLI')
    puts "It seems you do not have HandbrakeCLI installed or it is not available in your $PATH."
    puts "Install it an run again"
    exit 1
  end
  
  unless find_executable 'ffprobe'
    puts "It seems you do not have ffprobe installed or it is not available in your $PATH."
    puts "ffprobe is part of ffmpeg. Install it for your system and run again."
    exit 1
  end
  
  File.delete 'mkmf.log' # find_executable seems to create such file in case executable is not found
  
  StreamStruct = Struct.new(:count,:names)
  CONVERT_TYPES = ['mkv','avi','mov','flv','mpg','wmv']
  #HANDBRAKE_OPTIONS = "--encoder x264 --quality 20.0 --aencode faac -B 160 --mixdown dpl2 --arate Auto -D 0.0 --format mp4 --markers --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 --x264-preset veryfast --loose-anamorphic --modulus 2"
  FFMPEG_OPTIONS = "-map 0 -acodec copy -vcodec copy -scodec copy"
  
  
  log "probing for target files..."
  target_files = []
  if File.directory?(TARGET_PATH)
    
    scope = options[:recursive] ? "/**/*" : "/*"
    
    Dir[TARGET_PATH + scope].each do |file|
      unless File.directory?(file)
        target_files << file if CONVERT_TYPES.include?(File.extname(file).downcase[1..-1]) 
      end
    end

    #Dir.entries(TARGET_PATH).each do |file|
    #  target_files << file if CONVERT_TYPES.include?(File.extname(file).downcase[1..-1])
    #end
  else
    target_files << File.absolute_path(TARGET_PATH)
  end
  
  log "Files found:"
  target_files.each do |file|
    relative_path = file[TARGET_PATH.length+1..-1]
    puts "* #{relative_path}"
  end

  #Dir.chdir(TARGET_PATH)
  
  target_files.each do |infile|
    
    metadata = ffprobe(infile)
    if metadata.nil?
      log "ERROR retrieving metadata -- skipping this file"
      next
    end
    
    astreams = StreamStruct.new(0,[]) # audio streams
    sstreams = StreamStruct.new(0,[]) # subtitle streams
    
    metadata['streams'].each do |stream|
      case stream['codec_type']
      when 'audio'  
        astreams.count += 1
        astreams.names << stream['tags']['title'] unless stream['tags'].nil? || stream['tags']['title'].nil?
      when 'subtitle' 
        sstreams.count += 1
        sstreams.names << stream['tags']['title'] unless stream['tags'].nil? || stream['tags']['title'].nil?
      else 
        # this is attachment stuff, like typefonts --> ignore
      end
    end

    infile_noext = File.join( File.dirname(infile), File.basename(infile,File.extname(infile)))
    infile_basename = File.basename(infile)
    infile_basename_noext = File.basename(infile, File.extname(infile)) # without ext
    infile_dirname = File.dirname(infile)
    infile_relative = infile[infile_dirname.length+1..-1]

    #filename = File.basename(infile, File.extname(infile)) # without ext
    #outfile = "#{filename}.mp4"
    outfile = "#{File.join(infile_dirname, infile_basename_noext)}.mp4"
    
    #log "processing: #{infile}"
    log "processing: #{infile_relative}" 

    #%x( #{HANDBRAKE_CLI} #{HANDBRAKE_OPTIONS} --audio #{(1..astreams.count).to_a.join(',')} --aname #{astreams.names.join(',')} --subtitle #{(1..sstreams.count).to_a.join(',')} -i \"#{infile}\" -o \"#{outfile}\" 2>&1 )
    
    begin
      
      HandBrake::CLI.new.input(infile).encoder('x264').quality('20.0').aencoder('faac').
      ab('160').mixdown('dpl2').arate('Auto').drc('0.0').format('mp4').markers.
      audio_copy_mask('aac,ac3,dtshd,dts,mp3').audio_fallback('ffac3').x264_preset('veryfast').
      loose_anamorphic.modulus('2').audio((1..astreams.count).to_a.join(',')).aname(astreams.names.join(',')).
      subtitle((1..sstreams.count).to_a.join(',')).output(outfile)
      
      # if we make it here, encoding went well
      log "SUCCESS: encoding done"
      
      infile_size = File.size(infile)
      outfile_size = File.size(outfile)

      log "Compression ratio: %.2f" % (outfile_size.to_f / infile_size.to_f)
      
      if options[:move]
        #log "renaming #{infile} to .old"
        #File.rename infile, "#{infile}.old" 
        
        log "moveing #{infile_relative} to *.old"
        File.rename infile, "#{infile}.old"
      end
      
      if options[:title]
        log "setting mp4 title"
        
        #tmpfile = filename + ".tmp.mp4"
        tmpfile = infile_noext + ".tmp.mp4"
        
        %x( ffmpeg -i \"#{outfile}\" -metadata title=\"#{filename}\" #{FFMPEG_OPTIONS} \"#{tmpfile}\" 2>&1 )
        
        if $?.exitstatus == 0
          begin
            File.delete outfile
            File.rename tmpfile, outfile 
          rescue
            log "ERROR: moving #{tmpfile} to #{outfile}"
          end
        else
          log "ERROR: mp4 title could not be changed"
        end
      end # if options[:title]
      
    rescue 
      log "ERROR: Handbrake exited with an error"
    end # HandBrake::CLI
    
  end # target_files.each
  
  if target_files.empty?
    log "nothing to do"
  else
    log "all items processed"
  end
end