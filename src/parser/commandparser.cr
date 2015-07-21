# Command parser, uses the stringparser
require "concurrent"

require "./argparser.cr"

class CommandParser
	property commands
	property helpdata
	property aliases

	@recursionlimit = 16
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
				snippet = args[1]?
				if !snippet.is_a? String # Get alias
					als = @aliases[als_name]?
					if als.is_a? String
						output.send als
					else
						output.send "#{als_name} not defined"
					end
				elsif snippet.is_a? String # Set alias
					if snippet == ""
						output.send "Cleared alias #{als_name}"
					else
						begin
							cmd = parse_args(snippet)
							@aliases[als_name] = snippet
							output.send "Set alias #{als_name}"
						rescue e : ArgumentError
							output.send "Error: #{e.to_s}"
						end
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

	def parse(nick, channel, string, callcount=0 : Int, checkaliases=true, checkbackticks=true)
		callcount = callcount + 1
		if callcount >= @recursionlimit
			raise "Error: Recursion limit reached. (Max #{@recursionlimit} invocations)"
		end
		if string =~ /^\s*$/
			return ""
		end
		if checkbackticks
			string = parse_backticks(nick, channel, string, callcount)
		end
		cmds = parse_args(string)

		input = BufferedChannel(String).new
		input.close
		output = BufferedChannel(String).new
		cmds.each_with_index {|i, n|
			cmd = n[0]
			args = n[1..n.length]
			input, output = spawn_call nick, channel, cmd, args, input, output, callcount, checkaliases
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
	def parse(nick, channel, cmds : Hash(Int32, Array(String)), input, callcount, checkaliases=true)
		input = BufferedChannel(String).new
		input.close
		output = BufferedChannel(String).new
		cmds.each_with_index {|i, n|
			cmd = n[0]
			args = n[1..n.length]
			input, output = spawn_call nick, channel, cmd, args, input, output, callcount, checkaliases
		}
		output
	end

	def spawn_call(nick, chan, cmd, args, input, output, callcount, checkaliases=true)
		spawn {
			call_cmd nick, chan, cmd, args, input, output, callcount, checkaliases
		}
		input, output = output, BufferedChannel(String).new
		return input, output
	end
	def call_cmd(nick, chan, cmd, args, input, output, callcount, checkaliases=true)
		begin
			fn = @commands[cmd]?
			als = @aliases[cmd]?
			if fn.is_a? Proc
				fn.call nick, chan, args, input, output
				output.close if !output.closed?
			elsif checkaliases && als.is_a? String
				parsed = parse_args parse_backticks(nick, chan, als, callcount)
				# add parsed and args together
				cmds = parsed
				cmds[cmds.length-1] = cmds[cmds.length-1].concat args
				output_cmd = parse(nick, chan, cmds, input, callcount, true)
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
	def parse_backticks(nick, channel, string : String, callcount)
		i = 0
		len = string.length
		current = ""
		out = [] of String
		isquote = false
		issinglequote = false
		while i < len
			ch = string[i]
			nxt = string[i+1]?
			prv = string[i-1]?
			if ch == '"'
				#found, pos = after(string, i + 1, '"', true)
				#raise ArgumentError.new("Unmatched Quotes. (\")") if !found
				#out[c] << string[i+1..pos-1].gsub(/\\(.)/) {|m| m[1]}
				isquote = !isquote
				current = current + ch
				i = i + 1
			elsif ch == '\''
				issinglequote = !issinglequote
				current = current + ch
				i = i + 1
			elsif ch == '\\'
				if nxt.is_a? Char
					current = current + ch + nxt
					i = i + 2
				else
					raise ArgumentError.new("Unmatched Escapes. (\\)")
				end
			elsif ch == '`' && !isquote && !issinglequote
				out << current
				current = ""
				found, pos = after(string, i + 1, '`', true)
				raise ArgumentError.new("Unmatched Backticks. (\`)") if !found
				cmd = string[i+1..pos-1]#.gsub(/\\(.)/) {|m| m[1]}
				out << parse(nick, channel, cmd, callcount, true, true)
				i = pos + 1
			else
				current = current + ch
				i = i + 1
			end
		end
		if current != ""
			out << current
		end
		final = ""
		out.each {|s| final = final + s}
		final
	end
end
