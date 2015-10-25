# IRC stuff.
require "socket"
require "openssl"

require "../output/*"

class IRC
	property nick
	property username
	property realname
	property socket

	# Initialization methods and stuff.
	def initialize(@server : String, @port : Int, @nick : String, @user : String, @realname="Cry" : String, @ssl=false : Bool, @pass=nil : Nil | String)
		socket = TCPSocket.new @server, @port
		socket = OpenSSL::SSL::Socket.new socket if @ssl
		@socket = socket

		nick @nick
		send "USER #{@user} ~ ~ :#{@realname}"
		@socket.flush
		while true
			msg = receive()
			if msg.is_a? String
				Output.receivedline msg
				break if msg.includes? ":End of /MOTD command."
			end
		end
	end
	###
	#  Helper functions.
	###
	# Connection functions
	def nick nick : String
		send "NICK #{nick}"
	end
	def receive
		msg = @socket.read_line
		if msg.is_a? String && !msg.empty?
			if /^PING :(.*)$/.match msg
				send "PONG #{$~[1]}"
			end
			return msg.delete("\r\n")
		end
		return nil
	end
	def run(&block : String ->)
		while true
			msg = receive()
			if msg.is_a? String
				yield msg
			end
		end
	end
	def quit reason=""
		send "QUIT" if reason == ""
		send "QUIT :#{reason}"
	end

	# Message sending functions
	def send msg=""
		if msg != ""
			@socket.puts(msg + "\r\n")
			Output.sentline msg
			@socket.flush
		end
	end
	def msg chan : String, msg : String
		msg.each_line {|line|
			if line != ""
				length = 512-("PRIVMSG #{chan} :").size
				send "PRIVMSG #{chan} :" + line
			end
		}
	end
	def notice chan : String, msg : String
		msg.each_line {|line|
			length = 512-("PRIVMSG #{chan} :").size
			send "PRIVMSG #{chan} :" + line
		}
	end

	# Channel functions
	def join chan : String
		send "JOIN #{chan}"
	end
	def part chan : String
		send "PART #{chan}"
	end
	def mode chan : String, mode : String, nick : String
		send "MODE #{chan} #{mode} #{nick}"
	end
end
