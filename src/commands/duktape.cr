# Duktape, wip, probably not working.
require "../parser/commandhelper.cr"

require "duktape"

class DuktapeCommands
	def initialize(parser : CommandParser)
			@duk = DuktapeWrapper.new

			while true
				# A bit more testing and stuff.
				@duk.eval("Math.PI")
				@duk.eval("Math")
				break if @duk.eval("'test'") == "test"
			end
			@duk.eval!("Math")

			parser.command "duktape", "run javascript using the duktape engine" {|a|
				if !a.args.empty?
					str = a.raw.gsub(/^#{a.cmd} /, "")
					puts str
					puts a.raw

					begin
						a.output.send "#{@duk.eval!(str)}"
					rescue e
						a.output.send "Error: #{e}"
					end
				else
					a.output.send "Usage: duktape [js]"
				end
			}
	end
end
class DuktapeWrapper
	def initialize(timeout = 500)
		@sbx :: Duktape::Sandbox
		reset timeout
	end

	def reset(timeout)
		@sbx = Duktape::Sandbox.new timeout

		while true
			break if eval("'a'") == "a"
		end

		bindings
	end

	def bindings
		#@sbx.push_global_object
		#@sbx.push_proc(1) do |ptr| # write
		#	env = Duktape::Sandbox.new ptr
		#	txt = env.get_string 0
		#	if txt.is_a? String
		#		@output.push txt
		#	end
		#	env.return 1 # return success
		#end
		#@sbx.put_prop_string -2, "write"

		@sbx.eval "
		print = null
		"
	end

	def eval(code)
		r = @sbx.eval code
		#out = get_global_var "__OUTPUT__"
		#@sbx.eval! "var __OUTPUT__ = \"\";"
		#out
		get_val -1
	end
	def eval!(code)
		r = @sbx.eval! code
		#out = get_global_var "__OUTPUT__"
		#@sbx.eval! "var __OUTPUT__ = \"\";"
		#out
		get_val -1
	end

	def get_val(index)
		case
		when @sbx.is_string(index)
			@sbx.get_string(index)
		when @sbx.is_number(index)
			@sbx.get_number(index)
		else
			@sbx.to_string(index)
			v = @sbx.get_string(index)
			@sbx.pop
			v
		end
	end

	def get_global_var(name)
		@sbx.push_global_object
		@sbx.push_string name
		t = get_val -1
		@sbx.pop
		t
	end
end
