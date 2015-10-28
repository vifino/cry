# Arg parser
# Parses the string to a usable datastructure.
class CommandParser
	def parse_args(string : String)
		c = 0
		i = 0
		len = string.size
		output = Hash(Int32, Array(String)).new
		rawlines = Array(String).new
		lastpipe=0
		current = ""
		while i < len
			output[c] = Array(String).new(10)
			while i < len
				ch = string[i]
				nxt = string[i+1]?
				prv = string[i-1]?
				if ch == '"'
					found, pos = after(string, i + 1, '"', true)
					raise ArgumentError.new("Unmatched Quotes. (\")") if !found
					if current != ""
						output[c] << current
						current = ""
					end
					output[c] << string[i+1..pos-1].gsub(/\\(.)/) {|m|
						case m[1]
						when 'n'
							"\n"
						when 'r'
							"\r"
						else
							m[1]
						end
					}
					i = pos + 1
				elsif ch == '\''
					found, pos = after(string, i + 1, '\'', true)
					raise ArgumentError.new("Unmatched Quotes. (')") if !found
					if current != ""
						output[c] << current
						current = ""
					end
					output[c] << string[i+1..pos-1]
					i = pos + 1
				elsif ch == '|'
					if current != ""
						output[c] << current
						current = ""
					end
					i = i + 1
					rawlines << string[lastpipe..i-2].strip if string[lastpipe..i-2]!=""
					lastpipe=i
					break
				elsif ch == '\\'
					if nxt.is_a? Char
						case nxt
						when 'n'
							current = current + '\n'
						when 'r'
							current = current + '\r'
						else
							current = current + nxt
						end
						i = i + 2
					else
						raise ArgumentError.new("Unmatched Escapes. (\\)")
					end
				elsif ch == ' '
					if current != ""
						output[c] << current
						current = ""
					end
					i = i + 1
				else
					current = current + ch
					i = i + 1
				end
			end
			output[c] << current if current != ""
			c = c + 1
		end
		rawlines << string[lastpipe..i].strip if string[lastpipe..i]!=""
		return output, rawlines
	end

	def self.parse_args(string : String)
		parse_args(string)
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
