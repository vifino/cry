# Permission checking commands
class PermissionCommands
	def initialize(parser : CommandParser, permissions : Permissions)
		parser.command "groups", "display current group names" {|nick, chan, args, input, output|
			perms = permissions.users[nick]?
			if perms.is_a? Array
				res = ""
				perms.each {|g|
					res = res + g + " "
				}
				output.send res
			else
				output.send "No groups."
			end
		}
		parser.command "sudo", "execute a command as another user" {|nick, chan, args, input, output|
			if args[0]? != nil
				user = args[0]
				command = args[1..args.length]
				if permissions.user_hasprivilege(nick, "sudo")
					cmd = command[0]?
					if cmd.is_a? String
						parser.call_cmd(user, chan, cmd, command[1..args.length], input, output)
					else
						output.send "Usage: sudo user [command...]"
					end
				else
					output.send "No permission to do that. (sudo)"
				end
			else
				output.send "Usage: sudo user [command...]"
			end
		}
	end
end
