# Basic commands, such as cat, echo or rot13.
class BasicCommands
	def initialize(parser : CommandParser)
		parser.command "echo", "display a line of text" {|args, input, output|
			str = ""
			args.each {|s| str = str + s + " "}
			output.send(str.strip)
		}
		parser.command "cat", "read input, write output" {|args, input, output|
			while true
				if input.closed?
					output.close
					break
				end
				inp = input.receive?
				if inp.is_a? String
					output.send inp
				end
			end
		}
		parser.command "rot13", "decrypt caesar ciphers" {|args, input, output|
			while true
				if input.closed?
					output.close
					break
				end
				inp = input.receive?
				if inp.is_a? String
					output.send inp.tr("abcdefghijklmnopqrstuvwxyz", "nopqrstuvwxyzabcdefghijklm")
				end
			end
		}
	end
end
