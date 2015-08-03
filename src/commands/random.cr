# Basic commands, such as echo, cat or rot13.
require "../parser/commandhelper.cr"
class RandomCommand
	def initialize(parser : CommandParser)
		parser.command "rnd", "prints a random number between 0 and 100" {|a|
			prng = Random.new
			a.output.send prng.rand(101)
		}
	end
end