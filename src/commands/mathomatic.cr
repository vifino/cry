# Math plugin using mathomatic, linux-only. Need to have mathomatic installed.
require "../parser/commandhelper.cr"
class MathomaticCommands
	def initialize(parser : CommandParser)
		parser.command "solve", "calculate/solve an expression" {|a|
			if a.args[0]? != nil
				args = ["-qcs", "4:10"]
				str = ""
				a.args.each {|s|
					str = str + s.tr(";", "\n") + " "
				}
				str.split("\n").each {|s|
					args.push "-e"
					args.push s.strip
				}
				process = Process.new("mathomatic", args, shell: false, input: true, output: nil, error: true)
				output = process.output.gets_to_end
				status = process.wait

				if status.success?
					res = ""
					output.split("\n").each_with_index {|line, index|
						next if index == 0
						next if line == ""
						res = res + line + "\n" if !line.strip.empty?
					}
					a.output.send res
				else
					a.output.send "Error."
				end
			else
				a.output.send "Usage: solve [expr]"
			end
		}
		parser.command "calc", "calculate/solve an expression", "solve"
	end
end
