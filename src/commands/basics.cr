# Basic commands, such as cat, echo or rot13.
class BasicCommands
	def initialize(parser : CommandParser)
		parser.command "cat", "read input, write output" {|args, input, output|
			while true
				inp = input.receive
				puts inp
				output.send inp
			end
			output.close
		}
		parser.command "rot13", "decrypt caesar ciphers" {|args, input, output|
			while true
				output.send input.receive().tr("abcdefghijklmnopqrstuvwxyz", "nopqrstuvwxyzabcdefghijklm")
			end
			output.close
		}
	end
end
