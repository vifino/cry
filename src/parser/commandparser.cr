# Command parser, uses the stringparser
require "concurrent"

require "./argparser.cr"

class CommandParser
	property commands
	property helpdata
	property aliases

	@noman = "No manual entry available for $NAME$"

	def initialize
		@commands = Hash(String, (String, String, Array(String), BufferedChannel(String), BufferedChannel(String) ->)).new
		@helpdata = Hash(String, String).new
		@aliases = Hash(String, String).new
		command "man", "an interface to the command reference manuals" {|nick, chan, args, input, output|
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
		command "alias", "define or display aliases" {|nick, chan, args, input, output|
			als_name = args[0]?
			if als_name.is_a? String
				snippet = args[1]? || ""
				if !snippet.is_a? String # Get alias
					als = @aliases[als_name]?
					if als.is_a? String
						output.send als
					else
						output.send "#{als_name} not defined"
					end
				else # Set alias
					begin
						cmd = parse_args(snippet)
						@aliases[als_name] = snippet
						output.send "Set alias #{als_name}"
					rescue e : ArgumentError
						output.send "Error: #{e.to_s}"
					end
				end
			else
				output.send "Usage: alias test [\"echo test\"]"
			end
		}
	end

	# Command helpers and overload.
	def command(name : String, help=@noman : String, &block : String, String, Array(String), BufferedChannel(String), BufferedChannel(String) ->)
		@commands[name] = block
		@helpdata[name] = help.gsub(/\$NAME\$/, name)
	end
	#def command(name : String, help=@noman : String, &block : Array(String), BufferedChannel(String), BufferedChannel(String) ->)
	#	@commands[name] = ->(nick : String, chan : String, args : Array(String), input : BufferedChannel(String), output : BufferedChannel(String)) {
	#		block.call args, input, output
	#	}
	#	@helpdata[name] = help.gsub(/\$NAME\$/, name)
	#end

	def parse(nick, channel, string, checkaliases=true)
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
			input, output = spawn_call nick, channel, cmd, args, input, output, checkaliases
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
	def parse(nick, channel, cmds : Hash(Int32, Array(String)), input, checkaliases=true)
		input = BufferedChannel(String).new
		input.close
		output = BufferedChannel(String).new
		cmds.each_with_index {|i, n|
			cmd = n[0]
			args = n[1..n.length]
			input, output = spawn_call nick, channel, cmd, args, input, output, checkaliases
		}
		output
	end

	private def spawn_call(nick, chan, cmd, args, input, output, checkaliases=true)
		spawn {
			call_cmd nick, chan, cmd, args, input, output, checkaliases
		}
		input, output = output, BufferedChannel(String).new
		return input, output
	end
	def call_cmd(nick, chan, cmd, args, input, output, checkaliases=true)
		begin
			fn = @commands[cmd]?
			als = @aliases[cmd]?
			pp als
			if fn.is_a? Proc
				fn.call nick, chan, args, input, output
				output.close if !output.closed?
			elsif checkaliases && als.is_a? String
				puts "Alias"
				parsed = (parse_args als)
				# add parsed and args together
				cmds = parsed
				cmds[cmds.length-1] = cmds[cmds.length-1].concat args
				output_cmd = parse(nick, chan, cmds, input, false)
				while true
					if output_cmd.closed?
						break
					end
					inp = output_cmd.receive?
					if inp.is_a? String
						output.send inp
					else
						break
					end
				end
				output.close
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
