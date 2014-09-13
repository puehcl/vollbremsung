# vollbremsung: Handbrake bulk encoding tool

[![Gem Version](https://badge.fury.io/rb/vollbremsung.svg)](http://badge.fury.io/rb/vollbremsung)

## Installation

Just run ```gem install vollbremsung```

## Usage

	vollbremsung [options] <target>
	
`vollbremsung` is a HandbrakeCLI bulk encoding tool. If `<target>` is a file, it will be processed by Handbrake using a modified version of the default preset which will take all audio and subtitle tracks in their order of appearence (Handbrake default takes only the first).

If `<target>` is a directory, all files with one of the file extensions [ mkv | avi | mov | flv | mpg | wmv | ogm ] will be be processed. See the following options for additional actions.
	
### Options

    -d, --delete                     Delete source files after successful encoding
        --list-only                  List matching files only. Do not run processing
    -m, --move                       Move source files to <FILENAME>.old after encoding
    -r, --recursive                  Process subdirectories recursively as well
    -t, --title                      Set the MP4 metadata title tag to the filename
        --x264-preset [PRESET]       Set the x264-preset. Default is: veryfast
        --version                    Show program version information
    -h, --help                       Show this message
	
## Etymology

"*vollbremsung*" means "*full application of the brake*" in german.
