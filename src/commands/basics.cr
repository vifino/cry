# Basic commands, such as echo, cat or rot13.
require "../parser/commandhelper.cr"
class BasicCommands
	def initialize(parser : CommandParser)
		parser.command "echo", "display a line of text" {|a|
			str = ""
			a.args.each {|s| str = str + s + " "}
			a.output.send str.strip
		}
		parser.command "whoami", "print effective userid" {|a|
			a.output.send a.nick
		}
		parser.command "cat", "read a.input, write a.output" {|a|
			CommandHelper.pipe(a.input, a.output)
		}
		parser.command "rot13", "decrypt caesar ciphers" {|a|
			CommandHelper.pipe(a.input, a.output) {|s|
				s.tr("abcdefghijklmnopqrstuvwxyz", "nopqrstuvwxyzabcdefghijklm")
			}
		}
		parser.command "date", "display the current time" {|a|
			if a.args[0]? == nil
				a.output.send Time.utc_now.to_s("%a %b %d %T UTC %Y")
			else
				begin
					a.output.send Time.utc_now.to_s(a.args[0])
				rescue e
					a.output.send "Invalid format."
				end
			end
		}
		parser.command "time", "time a simple command" {|a|
			if a.args[0]? != nil
				command = a.args[0..a.args.length]
				cmd = command[0]?
				start = Time.now
				outp = BufferedChannel(String).new
				parser.call_cmd(a.nick, a.chan, cmd, command[1..command.length], a.input, outp, a.callcount)
				CommandHelper.pipe(outp, a.output)
				a.output.send "\nTook: #{Time.new - start}"
			else
				a.output.send "Usage: time [command...]"
			end
		}
		parser.command "tr", "translate or delete characters" {|a|
			if a.args[0]? != nil
				set1 = a.args[0]
				set2 = a.args[1]? || ""
				while true
					if a.input.closed?
						break
					end
					inp = a.input.receive?
					if inp.is_a? String
						a.output.send inp.tr(set1, set2)
					end
				end
			else
				a.output.send "Usage: tr SET1 [SET2]"
			end
		}
        parser.command "rnd", "prints a random number between 0 and 100" {|a|
			prng = Random.new
			a.output.send prng.rand(101)
		}
	end
end
