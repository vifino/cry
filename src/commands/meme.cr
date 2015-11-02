# Commands following memes. Totally useful.
require "../parser/commandhelper.cr"
class MemeCommands
	def initialize(parser : CommandParser)
		parser.command "noot", "Noot Noot!", "echo '🐧 NOOT NOOT! 🐧'"
	end
end
