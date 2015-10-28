# Duktape, wip, probably not working.
require "../parser/commandhelper.cr"

require "duktape"

class DuktapeCommands
	def initialize(parser : CommandParser)
			# @sbx = Duktape::Sandbox.new 500

			#@output :: Channel::Buffered(String)

			#bindings()

			parser.command "duktape", "run javascript using the duktape engine" {|a|
				str = ""
				a.args.each {|s| str = str + s + " "}

				begin
					run_js(str, a.output)
				rescue e
					a.output.send "Error: #{e}"
				end
			}
	end

	def run_js(str, output)
		sbx = Duktape::Sandbox.new 500

		# Sandbox methods and stuff.
		sbx.push_global_object
		sbx.push_proc(1) do |ptr| # write
			env = Duktape::Sandbox.new ptr
			txt = env.get_string 0
			if txt.is_a? String
				output.send txt
			end
			env.return 1 # return success
		end
		sbx.put_prop_string -2, "write"

		sbx.eval! "
		function print(txt) {
			write(txt + '\n')
		}
		"

		sbx.eval! str
	end
end
