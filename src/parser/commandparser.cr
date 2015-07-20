# Command parser, uses the stringparser
require "concurrent"

require "./argparser.cr"

class CommandParser
	property commands
	property helpdata

	@noman = "No manual entry available for $NAME$"

	def initialize
		@commands = Hash(String, (String, String, Array(String), BufferedChannel(String), BufferedChannel(String) ->)).new
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

	# Command helpers and overload.
	def command(name : String, help=@noman : String, &block : String, String, Array(String), BufferedChannel(String), BufferedChannel(String) ->)
		@commands[name] = block
		@helpdata[name] = help.gsub(/\$NAME\$/, name)
	end
	def command(name : String, help=@noman : String, &block : Array(String), BufferedChannel(String), BufferedChannel(String) ->)
		@commands[name] = ->(nick : String, chan : String, args : Array(String), input : BufferedChannel(String), output : BufferedChannel(String)) {
			block.call args, input, output
		}
		@helpdata[name] = help.gsub(/\$NAME\$/, name)
	end

	def parse(nick, channel, string)
		if string =~ /^\s*$/
			return ""
		end
		cmds = parse_args(string)
		input = BufferedChannel(String).new
		input.close
		output = BufferedChannel(String).new
		cmds.each_with_index {|i, n|
			cmd = n[0]
			args = n[1..n.length]
			input, output = spawn_call nick, channel, cmd, args, input, output
		}
		out = ""
		while true
			begin
				out = out + output.receive
			rescue
				break
			end
		end
		out
	end
	private def spawn_call(nick, chan, cmd, args, input, output)
		spawn {
			call_cmd nick, chan, cmd, args, input, output
		}
		input, output = output, BufferedChannel(String).new
		return input, output
	end
	def call_cmd(nick, chan, cmd, args, input, output)
		begin
			fn = @commands[cmd]?
			if fn.is_a? Proc
				fn.call nick, chan, args, input, output
				output.close if !output.closed?
			else
				output.send "Error: No such command. (#{cmd})"
				output.close
			end
		rescue e
			output.send "Error: #{e.to_s}"
			output.close
		end
	end
end
