# Math plugin using mathomatic, linux-only. Need to have mathomatic installed.
require "../parser/commandhelper.cr"
class MathomaticCommands
	def initialize(parser : CommandParser)
		parser.command "solve", "calculate/solve an expression" {|a|
			if a.args[0]? != nil
				str = ""
				a.args.each {|s| str = str + s.tr(";", "\n") + " "}
				status = Process.run("mathomatic", args: ["-qcs", "4:10", "-e", str.strip], output: true)
				if status.success?
					output = status.output.not_nil!
					res = ""
					output.split("\n").each_with_index {|line, index|
						next if index == 0
						next if line == ""
						res = res + line.strip + "\n" if !line.strip.empty?
					}
					a.output.send res
				else
					a.output.send "Error."
				end
			else
				a.output.send "Usage: solve [expr]"
			end
		}
	end
end
