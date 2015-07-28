class CommandHelper
	def self.pipe(a : BufferedChannel(String), b : BufferedChannel(String))
		while true
			break if b.closed?
			tmp = a.receive?
			if tmp.is_a? String
				b.send tmp
			else
				break
			end
		end
	end

	def self.pipe(a : BufferedChannel(String), b : BufferedChannel(String), &block : String -> String)
		while true
			break if b.closed?
			tmp = a.receive?
			if tmp.is_a? String
				b.send block.call tmp
			else
				break
			end
		end
	end
	def self.readall(a : BufferedChannel(String))
		o = ""
		while true
			break if a.closed?
			tmp = a.receive?
			if tmp.is_a? String
				o = o + tmp
			else
				break
			end
		end
		o
	end
end
