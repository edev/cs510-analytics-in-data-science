def runsql(db, filename, header=nil, tabs=0)
    puts "\t" * tabs + header unless header.nil?
    puts "\t" * (tabs + 1) + "Read SQL from disk (#{filename})" unless header.nil?
    sql = File.read(filename)
    puts "\t" * (tabs + 1) + "Execute SQL" unless header.nil?
    db.execute sql
end

