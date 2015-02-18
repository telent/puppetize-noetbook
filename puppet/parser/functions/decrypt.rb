module Puppet::Parser::Functions
  newfunction(:decrypt, :type=>:rvalue) do |args|
    filename = args[0]
    `/usr/bin/gpg --use-agent --decrypt #{filename}`
  end
end
