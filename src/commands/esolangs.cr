# Esolang implementations.
require "../parser/commandhelper.cr"
class EsolangCommands
	def initialize(parser : CommandParser, permissions)

		parser.command "bf", "brainfuck interpreter" {|a|
			if !a.args.empty?
				insts = ""
				a.args.each {|a| insts = insts + a}
				bfdone = Channel::Buffered(Bool).new
				spawn {
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
