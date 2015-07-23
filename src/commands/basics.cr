# Basic commands, such as echo, cat or rot13.
require "../parser/commandhelper.cr"
class BasicCommands
	def initialize(parser : CommandParser)
		parser.command "echo", "display a line of text" {|nick, chan, args, input, output|
			str = ""
			args.each {|s| str = str + s + " "}
			output.send str.strip
		}
		parser.command "whoami", "print effective userid" {|nick, chan, args, input, output|
			output.send nick
		}
		parser.command "cat", "read input, write output" {|nick, chan, args, input, output|
			CommandHelper.pipe(input, output)
		}
		parser.command "rot13", "decrypt caesar ciphers" {|nick, chan, args, input, output|
			CommandHelper.pipe(input, output) {|s|
				s.tr("abcdefghijklmnopqrstuvwxyz", "nopqrstuvwxyzabcdefghijklm")
			}
		}
		parser.command "date", "display the current time" {|nick, chan, args, input, output|
			if args[0]? == nil
				output.send Time.utc_now.to_s("%a %b %d %T UTC %Y")
			else
				begin
					output.send Time.utc_now.to_s(args[0])
				rescue e
					output.send "Invalid format."
				end
			end
		}
		parser.command "time", "time a simple command" {|nick, chan, args, input, output|
			if args[0]? != nil
				command = args[0..args.length]
				cmd = command[0]?
				start = Time.now
				outp = BufferedChannel(String).new
				parser.call_cmd(nick, chan, cmd, command[1..command.length], input, outp)
				CommandHelper.pipe(outp, output)
				output.send "\nTook: #{Time.new - start}"
			else
				output.send "Usage: time [command...]"
			end
		}
		parser.command "tr", "translate or delete characters" {|nick, chan, args, input, output|
			if args[0]? != nil
				set1 = args[0]
				set2 = args[1]? || ""
				while true
					if input.closed?
						break
					end
					inp = input.receive?
					if inp.is_a? String
						output.send inp.tr(set1, set2)
					end
				end
			else
				output.send "Usage: tr SET1 [SET2]"
			end
		}
	end
end
