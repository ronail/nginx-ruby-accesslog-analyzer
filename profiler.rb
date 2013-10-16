require 'csv'

cnt = 0
slowest_record = nil
slowest_time = 0
limit = ARGV[1].nil? ? 0 : ARGV[1].to_i
File.readlines(ARGV[0]).each do |line|
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
