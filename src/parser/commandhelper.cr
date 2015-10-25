class CommandHelper
	def self.pipe(a : Channel::Buffered(String), b : Channel::Buffered(String))
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
	def pipe(a : Channel::Buffered(String), b : Channel::Buffered(String))
		self.pipe(a, b)
	end

	def self.pipe(a : Channel::Buffered(String), b : Channel::Buffered(String), &block : String -> String)
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
	def pipe(a : Channel::Buffered(String), b : Channel::Buffered(String), &block : String -> String)
		self.pipe(a, b, &block)
	end

	def self.readall(a : Channel::Buffered(String))
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
	def readall(a : Channel::Buffered(String))
		self.readall(a)
	end
	def self.reassembleraw(cmd, args)
		"#{cmd} #{self.reassemblerawargs(args)}"
	end
	def self.reassemblerawargs(args)
		raw = ""
		args.each {|s|
			s = s as String
			if (s.includes? ' ') || (s.includes? '\\')
				raw = raw + s.inspect + " "
			else
				raw = raw + s + " "
			end
		}
		raw
	end
end
