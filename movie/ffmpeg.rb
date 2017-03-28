#!/usr/bin/env ruby

require "ult"
extend Ult

def ffmpeg( command )
  puts command
  status, outputs, errors = execute( command )
  if 0 != status
    puts errors
    exit 2
  end
end

action = ARGV.shift
case action
when "join"
  input_files = []
  output_file = "output.mp4"
  scale = "960:540"
  option{
    on( "-i input" ){|value|
      if dir?( value )
        direach( value ){|name, path|
          input_files.push path if file?( path )
        }
      elsif file?( value )
        input_files.push value
      end
    }
    on( "-o output" ){|value|
      output_file = value
    }
    on( "-s scale" ){|value|
      options[ :scale ] = value
    }
    parse!( ARGV )
  }
  if input_files.empty?
    puts "Nothing input files"
    exit 1
  end
  
  # mp4 => ts
  ts_files = []
  tmp_files = []
  input_files.each_with_index{|input_file, i|
    case Ult.extname( input_file )
    when "ts"
      ts_file = input_file
    else
      ts_file = ".tmp_#{i}.ts"
      tmp_files.push ts_file
      ffmpeg( "ffmpeg -i #{input_file} -c copy -f mpegts -y #{ts_file}" )
    end
    ts_files.push "file '#{ts_file}'"
  }
  
  # ts => mp4
  concat_file = "#{output_file}.txt"
  mkfile( concat_file, "w" ){|file|
    file.puts ts_files
  }
  ffmpeg( "ffmpeg -f concat -i #{concat_file} -vf scale=#{scale} -y #{output_file}" )
  
  # delete temporary files
  tmp_files.each_with_index{|tmp_file|
    rmfile( "#{tmp_file}" )
  }
  rmfile( concat_file )
  
  puts "Joined: #{output_file}"
else
  puts "Unknown action: #{action}"
  exit 1
end
