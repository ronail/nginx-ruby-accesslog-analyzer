require 'csv'

require 'getoptlong'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--limit', '-l', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--size', '-s', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--threshold', '-t', GetoptLong::OPTIONAL_ARGUMENT]
)

filepath = nil
limit = 0
size = 1
threshold = 0
opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
Get the slowest api call from nginx access log file
usage: ruby profiler.rb [OPTION] ... FILE

-h, --help:
   show help

--limit x, -l x:
	maximun number of line to be processed

--size x, -s x:
	size of result set (default 1)

--threshold t, -t t
	threshold of time in second to be return


FILE: The path to the log file.
      EOF
    when '--limit'
    	limit = arg.to_i
    when '--size'
    	size = arg.to_i
    when '--threshold'
    	threshold = arg.to_f
  end
end

if ARGV.length < 1
  puts "Missing file argument (try --help)"
  exit 0
end

if size != 1 and threshold != 0
	puts "--size and --threshold cannot be used in the same time"
	exit 0
end

filepath = ARGV.shift

class NginxProfiler

	def initialize(filepath, options)
		@filepath = filepath
		@limit = options[:limit]
		@size = options[:size]
		@slowest_records = Array.new
		@last_time = 0
		@cnt = 0
		@threshold = options[:threshold]
	end

	def process_file
		File.readlines(@filepath).each do |record|
			# use row here...
			if @limit > 0 and @cnt >= @limit
				break
			end

			if @slowest_records.length == 0
				if @threshold > 0
					time = time_of_record record
					if time >= @threshold
						insert_record 0, record
					end
				else
					insert_record 0, record
				end
			else
				row = record.split
				time = time_of_record record
				hit = false
				if time > @last_time
					if @threshold > 0
						if time >= @threshold
							hit = true
						end
					else
						hit = true
					end
				elsif @slowest_records.length < @size
					hit = true
				end
				if hit
					index = position_of_record_with_time time
					if index >= 0
						insert_record index, record
					end
				end
			end
			@cnt += 1
		end
	end

	def time_of_record (record)
		row = record.split
		time = row[row.length - 1].to_f
	end

	def print_result
		@slowest_records.each do |record|
			puts record
		end
	end

	def position_of_record_with_time (time)
		index = 0
		for i in (@slowest_records.length - 1).downto 0
			t = time_of_record(@slowest_records[i]).to_f
			if (time < t)
				index = i + 1
				break;
			end
		end
		return index
	end

	def insert_record (index, record)
		@slowest_records.insert(index, record)
		if @threshold == 0
			@slowest_records = @slowest_records[0..@size]
		end
		@last_time = time_of_record @slowest_records.last
	end
end

profiler = NginxProfiler.new(filepath, {:limit => limit, :size => size, :threshold => threshold})
profiler.process_file
profiler.print_result