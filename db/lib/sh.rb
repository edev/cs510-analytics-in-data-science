##
# Invokes a shell command using ``, checks exit code, and exits (with error) on failure.
# On success, returns the captured contents of stdout from the command.
def sh(cmd)
    output = `#{cmd}`
    if !$?.success?
        puts "Command exited with failure code: #{cmd}"
        puts "Aborting."
        exit(1)
    end
    output
end


