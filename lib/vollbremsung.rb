module Vollbremsung
  
  USAGE   = "Usage: vollbremsung [options] <target>"
  VERSION = '0.0.16'
  CONVERT_TYPES = ['mkv','avi','mov','flv','mpg','wmv','ogm']
  FFMPEG_OPTIONS = "-map 0 -acodec copy -vcodec copy -scodec copy"
  X264_DEFAULT_PRESET = "veryfast"
  
  class StreamDescr < Struct.new(:count,:names)
    def initialize
      super(0,[])
    end
  end
  
end