# Tape! A tape as a simplistic store for data!
# I'm probably going to make a virtual fs later. Someday. Or never.
require "../parser/commandhelper.cr"
class TapeCommands
	property limit
	def initialize(parser)
		@limit = 1024
		@tapes = Hash(String, Tape).new
		@usage = "Usage: tape write [startpos] | tape read [startpos] [endpos] | tape size | tape usage | tape wipe"
		parser.command "tape", "read and write to tape" {|a|
			if !a.args.empty?
				@tapes[a.nick] = Tape.new(@limit) if !@tapes[a.nick]?
				case a.args[0]
				when "write"
					startpos = a.args[1]? || @tapes[a.nick].usage
					str = CommandHelper.readall(a.input)
					@tapes[a.nick].write(str, startpos.to_i)
				when "read"
					startpos = a.args[1]? || 0
					endpos = a.args[2]? || @limit
					a.output.send "#{@tapes[a.nick].read(startpos.to_i, endpos.to_i)}"
				when "wipe"
					@tapes[a.nick].wipe
					a.output.send "Wiped Tape."
				when "usage"
					a.output.send "#{@tapes[a.nick].usage}"
				when "size"
					a.output.send "#{@tapes[a.nick].size}"
				else
					a.output.send @usage
				end
			else
				a.output.send @usage
			end
		}
	end
end
class Tape
	property size
	def initialize(@size)
		@tape = ""
	end
	def usage
		@tape.length || 0
	end
	def read(start=0, end=@size)
		@tape[start..end] || ""
	end
	def write(string, startpos=0)
		#@tape[startpos..string.length] = string[0..@size-startpos]
		pos = 0
		tmp = ""
		while pos < @size
			if string[pos-startpos]? && pos >= startpos
				tmp = tmp + string[pos-startpos]
			else
				if @tape[pos]?
					tmp = tmp + @tape[pos]
				else
					tmp = tmp + " " if pos < startpos
				end
			end
			pos = pos + 1
		end
		@tape = tmp
	end
	def wipe
		@tape = ""
	end
end
