def execute( command, input = "", is_outputs = true, is_errors = true )
  status  = -1
  outputs = []
  errors  = []
  begin
    i_r, i_w = IO.pipe
    o_r, o_w = IO.pipe
    e_r, e_w = IO.pipe
    pid = Process.fork{
      i_w.close
      o_r.close
      e_r.close
      STDIN.reopen( i_r )
      STDOUT.reopen( o_w )
      STDERR.reopen( e_w )
      Process.exec( command )
    }
    o_w.close
    e_w.close
    i_r.close
    i_w.write input
    i_w.close
    
    Process.waitpid( pid )
    status = $?.exitstatus
  rescue => err
    if is_errors
      errors.push err.inspect
      errors.push err.backtrace
    end
  ensure
    o_r.each{|line| outputs.push line.chomp } if is_outputs
    e_r.each{|line| errors.push line.chomp } if is_errors
    o_r.close
    e_r.close
  end
  [ status, outputs, errors, command ]
end
