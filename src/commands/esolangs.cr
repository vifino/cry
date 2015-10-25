# Esolang implementations.
require "../parser/commandhelper.cr"
class EsolangCommands
	def initialize(parser : CommandParser, permissions)

		parser.command "bf", "brainfuck interpreter" {|a|
			if !a.args.empty?
				insts = ""
				a.args.each {|a| insts = insts + a}
				bfdone = Channel::Buffered(Bool).new
				Thread.new {
					Brainfuck.parse(a.output, insts, 1024).run
					bfdone.close
				}
				begin
					bfdone.receive
				rescue
				end
			else
				a.output.send "Usage bf [brainfuck instructions]"
			end
		}
		parser.command "forth", "forth interpreter" {|a|
			if !a.args.empty?
				forthout = Channel::Buffered(String).new
				Thread.new {
					forth = Forth.new(a.input, forthout, a, permissions)
					forth.parse(a.raw.gsub(/^#{a.cmd} /, ""))
					forthout.close
				}
				CommandHelper.pipe(forthout, a.output)
			else
				a.output.send "Usage: forth [TOKENS..]"
			end
		}
	end
end
class Brainfuck # Mostly stolen from Crystal's examples.
	struct Tape
		def initialize
			@tape = [0]
			@pos = 0
		end
		def get
			@tape[@pos]
		end
		def inc
			@tape[@pos] += 1
		end
		def dec
			@tape[@pos] -= 1
		end
		def advance
			@pos += 1
			@tape << 0 if @tape.size <= @pos
		end
		def devance
			@pos -= 1
			raise "pos should be > 0" if @pos < 0
		end
	end

	def initialize(@output, @chars, @bracket_map, @instlimit); end

	def run
		tape = Tape.new
		pc = 0
		inst = 0
		begin
			while pc < @chars.size
				inst += 1 if @instlimit != nil
				if inst > @instlimit
					raise "Instruction Limit reached. (#{@instlimit})"
				end
				case @chars[pc]
					when '>'; tape.advance
					when '<'; tape.devance
					when '+'; tape.inc
					when '-'; tape.dec
					when '.'; @output.send tape.get.chr.to_s
					when '['; pc = @bracket_map[pc] if tape.get == 0
					when ']'; pc = @bracket_map[pc] if tape.get != 0
				end
				pc += 1
			end
		rescue e
			@output.send "Error: #{e.to_s}"
		end
	end

	def self.parse(output, text, instlimit=nil)
		parsed = [] of Char
		bracket_map = {} of Int32 => Int32
		leftstack = [] of Int32
		pc = 0
		text.each_char do |char|
			if "[]<>+-,.".includes?(char)
				parsed << char
				if char == '['
					leftstack << pc
				elsif char == ']'
					raise ArgumentError.new("Unmatched ]") if leftstack.empty?
					left = leftstack.pop
					right = pc
					bracket_map[left] = right
					bracket_map[right] = left
				end
				pc += 1
			end
		end
		raise ArgumentError.new("Unmatched [") if !leftstack.empty?
		Brainfuck.new(output, parsed, bracket_map, instlimit)
	end
end
class Forth
	alias T = Int32 | String
	alias Word = ->

	def pop
		begin
			@stack.pop
		rescue
			raise("Stack Underflow")
		end
	end
	def push(expression : T)
		@stack << expression
	end
	def unary(&block : (T)->(T))
		-> { push(block.call pop) }
	end
	def binary(&block : (T, T)->(T))
		-> { swap; push(block.call pop, pop) }
	end
	def unary_boolean(&block : (T)->(Bool))
		-> { push(if block.call pop
				1
			else
				0
			end) }
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
		len = @stack.size
		last1 = @stack[len-1]
		last2 = @stack[len-2]
		@stack[len-2] = last1
		@stack[len-1] = last2
	end

	def new_word
		raise "Empty Word" if @word.size < 1
		raise "Nested Definition" if @word.includes? ":"
		name, expression = @word.shift, @word.join(" ")
		@customwords[name.to_s] = parse_raw(expression)
		@word = [] of T
		@def = false
	end

	def initialize(@input, @output, arguments, permissions)
		@def = false
		@skip = false
		@word = [] of String
		@stack = [] of T
		@dictionary = Hash(String, Word).new
		@dictionary = {
			# Operators
			"+"     => binary { |a, b|
					return a + b as Int32 if a.is_a? Int32 && b.is_a? Int32
					return a + b as String if a.is_a? String && b.is_a? String
					raise "Wrong types to +"
				},
			"-"     => binary { |a, b|
					return a - b as Int32 if a.is_a? Int32 && b.is_a? Int32
					raise "Wrong types to -"
				},
			"*"     => binary { |a, b|
					return a * b as Int32 if a.is_a? Int32 && b.is_a? Int32
					return a * b as Int32 if a.is_a? String && b.is_a? Int32
					raise "Wrong types to *"
				},
			"/"     => binary { |a, b|
					return (a / b as Int32) as Int32 if a.is_a? Int32 && b.is_a? Int32
					raise "Wrong types to /"
				},
			"%"     => binary { |a, b|
					return a ^ b as Int32 if a.is_a? Int32 && b.is_a? Int32
					raise "Wrong types to %"
				},
			"xor"   => binary { |a, b|
					return a ^ b as Int32 if a.is_a? Int32 && b.is_a? Int32
					raise "Wrong types to *"
				},
			"<"     => binary_boolean "<" { |a, b| a < b },
			">"     => binary_boolean ">" { |a, b| a > b },
			"="     => binary { |a, b| a == b ? 1 : 0 },
			"&"     => binary_boolean "&" { |a, b| a && b },
			"|"     => binary_boolean "|" { |a, b| a || b },
			"dup"   => -> { begin push(@stack.last) rescue raise("Stack Underflow") end },
			"over"  => -> { begin push(@stack[@stack.size-2]) rescue raise("Stack Underflow") end},
			"swap"  => -> { begin swap rescue raise("Stack Underflow") end },
			"not"   => unary_boolean { |a| a == 0 },
			"neg"   => unary { |a|
				if a.is_a? Int32
					-a
				else
					raise "Wrong type to neg"
				end
				},
			"concat"=> binary { |s1, s2|
				s1.to_s + s2.to_s
			},
			# Output
			"."     => -> { @output.send pop.to_s },
			"emit"  => -> { @output.send pop.to_s },
			".."    => -> { @output.send @stack.to_s },
			# Logic
			":"     => -> { @word = [] of String; @def = true },
			"pop"   => -> { pop },
			"words" => -> { @dictionary.keys.sort.each {|word| output.send word + " "} },
			"if"    => -> { @skip = true if pop == 0 },
			"else"  => -> { @skip = !@skip },
			"fi"    => -> { @skip = false },
			"nick"  => -> { push arguments.nick },
			"chan"  => -> { push arguments.chan },
			"hasgrp"=> binary { |user, group|
				if user.is_a? String && group.is_a? String
					return permissions.user_hasgroup(user, group) ? 1 : 0
				else
					raise "Wrong types for hasgrp"
				end
			}
		}
		@customwords = Hash(String, Array(String)).new
	end

	def parse(expression : Array(String))
		begin
			expression.each do |statement|
				if @skip == true && statement != "fi"
					next
				elsif @def && statement != ";"
					@word << statement
				elsif @def && statement == ";"
					new_word
				elsif @dictionary.has_key? statement
					@dictionary[statement].call
				elsif @customwords.has_key? statement
					parse(@customwords[statement])
				elsif /^"(.*)"$/.match statement
					push $~[1]
				else
					if isnumber(statement)
						push statement.to_i
					else
						raise "No such word: #{statement}"
					end
				end
			end
		rescue e
			@output.send "Error: #{e}"
		end
	end

	def parse(code : String)
		parse(parse_raw(code))
	end

	def isnumber(string)
		return !!(string =~ /\A[-+]?[0-9]+\z/)
	end

	private def parse_raw(string : String)
		i = 0
		len = string.size
		out = Array(String).new
		current = ""
		while i < len
			ch = string[i]
			nxt = string[i+1]?
			prv = string[i-1]?
			if ch == '"'
				found, pos = after(string, i + 1, '"', true)
				raise ArgumentError.new("Unmatched Quotes. (\")") if !found
				out << string[i..pos].gsub(/\\(.)/) {|m| m[1]}
				i = pos + 1
			elsif ch == '\''
				found, pos = after(string, i + 1, '\'', true)
				raise ArgumentError.new("Unmatched Quotes. (')") if !found
				s = string[i+1..pos-1].gsub(/\\(.)/) {|m| m[1]}
				out << "\"#{s}\""
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
			while i < string.size
				if string[i] == char && string[i-1]? != '\\'
					return true, i
				else
					i = i + 1
				end
			end
		else
			while i < string.size
				return true, i if string[i] == char
				i = i + 1
			end
		end
		return false, 0
	end
end
