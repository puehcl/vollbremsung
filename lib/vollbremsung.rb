module Vollbremsung
  
  USAGE   = "Usage: vollbremsung [options] <target>"
  VERSION = '0.0.4'
  CONVERT_TYPES = ['mkv','avi','mov','flv','mpg','wmv']
  FFMPEG_OPTIONS = "-map 0 -acodec copy -vcodec copy -scodec copy"
  
  class StreamDescr < Struct.new(:count,:names)
    def initialize
      super(0,[])
    end
  end
  
end