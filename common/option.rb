require "optparse"

def option( &block )
  OptionParser.new.instance_eval &block
end
