# Command parser
# Replace with actual(tm) parser later.
class CommandParser
	def parse_args(string)
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
				out << string[i+1..pos-1].gsub(/\\./, "\\1")
				i = pos + 1
			elsif ch == '\''
				found, pos = after(string, i + 1, '\'', true)
				raise ArgumentError.new("Unmatched Quotes. (')") if !found
				out << string[i+1..pos-1].gsub(/(\\.)/, "\\1")
				i = pos + 1
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

	def after(string, pos, char, checkescapes=false)
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
