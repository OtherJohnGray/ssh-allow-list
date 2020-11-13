#!/usr/bin/ruby

# Log function so that we can record what commands were requested by Syncoid
def log(msg)
  ######## UPDATE THIS FOR YOUR ENVIRONMENT ##########
  File.write('/home/unprivilegeduser/wrap-zfs-send.log', "[#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}] #{msg}\n", mode: 'a')
  ####################################################
end

# Function to check whether a command is explicitly allowed by this script
def allowed?(cmd)

  ######## UPDATE THIS FOR YOUR ENVIRONMENT ##########
  pool = "(tank|bpool)"
  dataset = "(vms|root|boot|home)"
  path_element_pattern = "/(\\w|-)+\\.?(\\w|-)*"
  dataset_pattern_string  = "#{pool}/#{dataset}(#{path_element_pattern})*"
  snapshot_pattern_string = "#{dataset_pattern_string}(@|'@')autosnap_20\\d\\d-\\d\\d-\\d\\d_\\d\\d:\\d\\d:\\d\\d_(frequently|hourly|daily|monthly|yearly)"
  allowed_commands = [
    "exit",
    "echo -n",
    "command -v lzop",
    "command -v mbuffer",
    Regexp.new("^zpool get -o value -H feature@extensible_dataset '#{pool}'$"),
    Regexp.new("^zpool get -o value -H feature@extensible_dataset '#{pool}'$"),
    Regexp.new("^zfs list -o name,origin -t filesystem,volume -Hr '#{pool}/#{dataset}'$"),
    Regexp.new("^zfs get -H syncoid:sync '#{dataset_pattern_string}'$"),
    Regexp.new("^zfs get -Hpd 1 -t snapshot guid,creation '#{dataset_pattern_string}'$"),
    Regexp.new("^zfs get -Hpd 1 -t bookmark guid,creation '#{dataset_pattern_string}'$"),
    Regexp.new("^zfs send -w -nP (-I '#{snapshot_pattern_string}' )?'#{snapshot_pattern_string}'$"),
    Regexp.new("^ zfs send -w  (-I '#{snapshot_pattern_string}' )?'#{snapshot_pattern_string}' \\| lzop  \\| mbuffer  -q -s 128k -m 16M 2>/dev/null$"),
    Regexp.new("^zfs send -nP -t [0-9a-f\-]+$"),
    Regexp.new("^ zfs send -w  -t [0-9a-f\\-]+ \\| lzop  \\| mbuffer  -q -s 128k -m 16M 2>/dev/null$"),
  ]
  ####################################################


  return allowed_commands.any? do |pattern|
    pattern.is_a?(String) ? pattern == cmd : pattern =~ cmd
  end
end

# Get the command that was requested via SSH from an environment variable
cmd = ENV['SSH_ORIGINAL_COMMAND']


if allowed? cmd
  log "authorised command was : #{cmd}"
  # print result of command to SSH client via STDOUT
  # bash -c because Ruby.
  print `bash -c "#{cmd}"`
else
  log "ILLEGAL COMMAND: #{cmd}"
  # return failure to SSH client
  exit 1
end