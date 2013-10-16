require 'csv'

require 'getoptlong'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--limit', '-l', GetoptLong::OPTIONAL_ARGUMENT ]
)

filepath = nil
limit = 0
opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
hello [OPTION] ... FILE

-h, --help:
   show help

--limit x, -l x:
	maximun number of line to be processed


FILE: The path to the log file.
      EOF
      return
    when '--limit'
      limit = arg.to_i
  end
end

if ARGV.length < 1
  puts "Missing file argument (try --help)"
  exit 0
end

filepath = ARGV.shift

cnt = 0
slowest_record = nil
slowest_time = 0
File.readlines(filepath).each do |line|
	row = line.split
	# use row here...
	if limit > 0 and cnt >= limit
		break
	end

	time = row[row.length - 1].to_f
	if slowest_record.nil? or time > slowest_time
		slowest_time = time
		slowest_record = line
	end
	cnt += 1
end

puts slowest_record
