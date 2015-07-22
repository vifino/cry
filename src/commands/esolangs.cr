# Esolang implementations.
class EsolangCommands
	def initialize(parser : CommandParser)
		parser.command "bf", "brainfuck interpreter" {|nick, chan, args, input, output|
			if !args.empty?
				addr = 0
				inst = 0
				insts = ""
				inputcache = ""
				args.each {|a| insts = insts + a}
				tape = Hash(Int32, Int32).new
				tape[0] = 0
				while true
					puts "Loop - addr:#{addr} inst:#{inst} = #{insts[inst]}"
					break if inst >= insts.length
					case insts[inst]
					when '+'
						if tape[addr] >= 256
							tape[addr] = 0
						else
							tape[addr] += 1
						end
					when '-'
						if tape[addr] < 0
							tape[addr] = 255
						else
							tape[addr] -= 1
						end
					when '>'
						addr += 1
						tape[addr] = 0 if !tape.has_key? addr
					when '<'
						addr -= 1
						tape[addr] = 0 if !tape.has_key? addr
					when '.'
						puts "output"
						output.send tape[addr].chr.to_s
					when '['
						inst = bf_scan(inst, 1, insts) if tape[addr] == 0
					when ']'
						inst = bf_scan(inst, -1, insts) if tape[addr] != 0
					end
					inst +=1
				end
			end
			puts "done."
		}
		parser.command "forth", "forth interpreter" {|nick, chan, args, input, output|
			forth = Forth.new(input, output)
			forth.parse(args)
		}
	end
	private def bf_scan(inst : Int32, dir : Int32, insts : String)
		nest = dir
		while dir*nest > 0
			inst += dir
			case insts[inst + dir]
			when '['
				nest += 1
			when ']'
				nest -= 1
			end
		end
		return inst
	end
end
class Forth # Do not use. It's broken.
	alias T = Int32 | String

	def pop
		@stack.pop || raise("Stack Underflow")
	end
	def push(expression : T)
		@stack << expression
	end
	def unary(&block : (T)->(T))
		-> { push(block.call pop) }
	end
	def binary(&block : (T, T)->(T))
		-> { push(block.call pop, pop) }
	end
	def unary_boolean(&block : (T)->(Bool))
		-> { push(if block.call pop then 1 else 0 end) }
	end
	def binary_boolean(name="instruction", &block : (Int32, Int32)->(Bool | Int32))
		-> {
			a = pop
			b = pop
			if a.is_a? Int32 && a.is_a? Int32
				res = block.call a, b as Int32
				res = if res.is_a? Int32
					res > 0
				end
				push(if res
					1
				else
					0
				end)
			else
				raise "Wrong types to #{name}"
			end
		}
	end
	def swap
		len = @stack.length
		last1 = @stack[len-1]
		last2 = @stack[len-2]
		@stack[len-2] = last1
		@stack[len-1] = last1
	end

	def new_word
		raise "Empty Word" if @word.size < 1
		raise "Nested Definition" if @word.includes? ":"
		name, expression = @word.shift, @word.join(" ")
		@customwords[name.to_s] = parse_args(expression)
		@word = [] of T
	end

	def initialize(@input, @output)
		@skip = false
		@word = [] of String
		@stack = [] of T
		@dictionary = {
			"+"     => binary { |a, b|
					return a + b as Int32 if a.is_a? Int32 && a.is_a? Int32
					return a + b as String if a.is_a? String && a.is_a? String
					raise "Wrong types to +"
				},
			"-"     => binary { |a, b|
					return a - b as Int32 if a.is_a? Int32 && a.is_a? Int32
					raise "Wrong types to -"
				},
			"*"     => binary { |a, b|
					return a * b as Int32 if a.is_a? Int32 && a.is_a? Int32
					return a * b as Int32 if a.is_a? String && a.is_a? Int32
					raise "Wrong types to *"
				},
			"/"     => binary { |a, b|
					return a / b as Int32 if a.is_a? Int32 && a.is_a? Int32
					raise "Wrong types to /"
				},
			"%"     => binary { |a, b|
					return a ^ b as Int32 if a.is_a? Int32 && a.is_a? Int32
					raise "Wrong types to %"
				},
			"<"     => binary_boolean "<" { |a, b| a < b },
			">"     => binary_boolean ">" { |a, b| a > b },
			"="     => binary_boolean "=" { |a, b| a == b },
			"&"     => binary_boolean "&" { |a, b| a && b },
			"|"     => binary_boolean "|" { |a, b| a || b },
			"not"   => binary_boolean "not" { |a, b| a == 0 },
			"neg"   => binary { |a|
				if a.is_a? Int32
					-a
				else
					raise "Wrong type to neg"
				end
				},
			"."     => -> { @output.send pop.to_s },
			"emit"  => -> { @output.send pop.to_s },
			".."    => -> { @output.send @stack.to_s },
			":"     => -> { @word = [] of String },
			";"     => -> { new_word },
			"pop"   => -> { pop },
			"fi"    => -> { @skip = false },
			"words" => -> { @dictionary.keys.sort.each {|word| output.send word + " "} },
			"if"    => -> { @skip = true if pop == 0 },
			"dup"   => -> { push(@stack.last || raise("Stack Underflow")) },
			"over"  => -> { push(@stack[@stack.length-2] || raise("Stack Underflow")) },
			"swap"  => -> { begin swap rescue raise("Stack Underflow") end }
		}
		@customwords = Hash(String, Array(String)).new
	end

	def parse(expression : Array(String))
		begin
			expression.each do |statement|
				puts statement
				if @skip == true && statement == "fi"
					puts "skip"
					next
				elsif @word.empty? && statement == ";"
					puts "word empty"
					@word << statement
				elsif @dictionary.has_key? statement
					puts "calling"
					@dictionary[statement].call
				elsif @customwords.has_key? statement
					puts "custom"
					parse(@customwords[statement])
				else
					if isnumber(statement)
						push statement.to_i
					else
						push statement
					end
				end
			end
		rescue e
			@output.send "Error: #{e}"
		end
	end

	def isnumber(string)
		return !!(string =~ /\A[-+]?[0-9]+\z/)
	end

	private def parse_args(string : String)
		i = 0
		len = string.length
		out = Array(String).new
		current = ""
		while i < len
			ch = string[i]
			nxt = string[i+1]?
			prv = string[i-1]?
			if ch == '"'
				found, pos = after(string, i + 1, '"', true)
				raise ArgumentError.new("Unmatched Quotes. (\")") if !found
				out << string[i+1..pos-1].gsub(/\\(.)/) {|m| m[1]}
				i = pos + 1
			elsif ch == '\''
				found, pos = after(string, i + 1, '\'', true)
				raise ArgumentError.new("Unmatched Quotes. (')") if !found
				out << string[i+1..pos-1].gsub(/\\(.)/) {|m| m[1]}
				i = pos + 1
			elsif ch == '|'
				i = i + 1
				break
			elsif ch == '\\'
				if nxt.is_a? Char
					current = current + nxt
					i = i + 2
				else
					raise ArgumentError.new("Unmatched Escapes. (\\)")
				end
			elsif ch == ' '
				if current != ""
					out << current
					current = ""
				end
				i = i + 1
			else
				current = current + ch
				i = i + 1
			end
		end
		out << current if current != ""
		out
	end

	private def after(string, pos, char, checkescapes=false)
		i = pos
		if checkescapes
			while i < string.length
				if string[i] == char && string[i-1]? != '\\'
					return true, i
				else
					i = i + 1
				end
			end
		else
			while i < string.length
				return true, i if string[i] == char
				i = i + 1
			end
		end
		return false, 0
	end
end
