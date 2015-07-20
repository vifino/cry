# Command parser, uses the stringparser
require "concurrent"

require "./argparser.cr"

class CommandParser
	property commands
	property helpdata

	@noman = "No manual entry available for $NAME$"

	def initialize
		@commands = Hash(String, (Array(String), BufferedChannel(String), BufferedChannel(String) ->)).new
		@helpdata = Hash(String, String).new
		command "man", "an interface to the command reference manuals" {|args, input, output|
			name = args[0]?
			if name.is_a? String
				if @helpdata[name]? != nil
					output.send "#{name} - #{@helpdata[name]}"
				else
					output.send @noman.gsub(/\$NAME\$/, name)
				end
			else
				output.send "What manual page do you want?"
			end
			output.close
		}
	end

	def command(name : String, help=@noman : String, &block : Array(String), BufferedChannel(String), BufferedChannel(String) ->)
		@commands[name] = block
		@helpdata[name] = help.gsub(/\$NAME\$/, name)
	end

	def parse(nick, channel, string)
		cmds = parse_args(string)
		input = BufferedChannel(String).new
		input.close
		output = BufferedChannel(String).new
		error = BufferedChannel(String).new
		cmds.each_with_index {|i, n|
			cmd = n[0]
			args = n[1..n.length]
			spawn {
				begin
					fn = @commands[cmd]?
					if fn.is_a? Proc
						fn.call(args, input, output)
					else
						output.send "Error: No such command. (#{cmd})"
						output.close
					end
				rescue e
					output.send "Error: #{e.to_s}"
					output.close
				end
			}
			new_output = BufferedChannel(String).new
			input, output = output, new_output
		}
		out = ""
		while !output.closed?
			begin
				out = out + output.receive()
			rescue
				break
			end
		end
		out
	end
end
