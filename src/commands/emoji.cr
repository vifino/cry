# Emoji Plugin
require "../parser/commandhelper.cr"

require "emoji"

class EmojiCommands
	def initialize(parser : CommandParser)
		parser.command "emoji", "convert things like :heart to emoji" {|a|
			str = ""
			a.args.each {|s| str = str + s + " "}
			a.output.send Emoji.emojize(str)
		}
	end
end
