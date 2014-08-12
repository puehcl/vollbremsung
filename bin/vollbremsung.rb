#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

require 'optparse'
require 'mkmf' # part of stdlib
require 'open3'
require 'json'

def log(msg)
  puts $time.strftime("%Y-%m-%d %H:%M:%S") +  "\t #{msg}"
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
  
  $time = Time.new
  CONVERT_TYPES = ['mkv','avi','mov','flv','mpg','wmv']
  HANDBRAKE="-e x264 -q 20.0 -a 1 -E faac -B 160 -6 dpl2 -R Auto -D 0.0 -f mp4 -m --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 --x264-preset veryfast --loose-anamorphic --modulus 2"
  
  src_files = []
  
  Dir.entries(TARGET_DIR_PATH).each do |file|
    if CONVERT_TYPES.include?(File.extname(file).downcase[1..-1])
      src_files << file
    end
  end
  
  log "Files found:"
  puts src_files

  Dir.chdir(TARGET_DIR_PATH)
  
  src_files.each do |infile|
    
    metadata = probe(infile)
    
    audio_stream_count = 0
    audio_stream_names = []
    
    video_stream_count = 0
    video_stream_names = []
    
    subtitle_stream_count = 0
    subtitle_stream_names = []
    
    metadata['streams'].each do |stream|
      case stream['codec_type']
      when 'audio'  
        audio_stream_count += 1
        audio_stream_names << stream['tags']['title']
      when 'video' 
        video_stream_count += 1
        video_stream_names << stream['tags']['title']
      when 'subtitle' 
        subtitle_stream_count += 1
        subtitle_stream_names << stream['tags']['title']
      else 
        log "wow, there is a funny stream inside this file (codec_type: #{stream['codec_type']})"
      end
    end
    
    puts "audio stream count: #{audio_stream_count}"
    puts audio_stream_names.join(',')
    
    puts "video stream count: #{video_stream_count}"
    puts video_stream_names.join(',')
    
    puts "subtitle stream count: #{subtitle_stream_count}"
    puts subtitle_stream_names.join(',')
    
    audio_channel_info = (1..audio_stream_count).to_a.join(',')
    video_channel_info = (1..video_stream_count).to_a.join(',')
    subtitle_channel_info = (1..subtitle_stream_count).to_a.join(',')
    
    #outfile = "#{File.basename(infile)}.mp4"
    
    #log "#{infile} --> #{outfile}"
    
    #%x( HandbrakeCLI #{HANDBRAKE} -i \"#{infile}\" -o \"#{outfile}\" 2>&1 )
    
    #if $?.exitstatus == 0
    #  log "SUCCESS: encoding done"
    #else 
    #  log "ERROR: Handbrake exited with an error"
    #end
    log "" # just to make output prettier
  end
  
  log "conversion list FINISHED"

end