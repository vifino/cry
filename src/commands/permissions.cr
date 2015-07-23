# Permission checking commands
class PermissionCommands
	def initialize(parser : CommandParser, permissions : Permissions)
		parser.command "groups", "display current group names" {|a|
			perms = permissions.users[a.nick]?
			if perms.is_a? Array
				res = ""
				perms.each {|g|
					res = res + g + " "
				}
				a.output.send res
			else
				a.output.send "No groups."
			end
		}
		parser.command "sudo", "execute a command as another user" {|a|
			if a.args[0]? != nil
				user = a.args[0]
				command = a.args[1..a.args.length]
				if permissions.user_hasprivilege(a.nick, "sudo")
					cmd = command[0]?
					if cmd.is_a? String
						parser.call_cmd(user, a.chan, cmd, command[1..a.args.length], a.input, a.output, a.callcount)
					else
						a.output.send "Usage: sudo user [command...]"
					end
				else
					a.output.send "No permission to do that. (sudo)"
				end
			else
				a.output.send "Usage: sudo user [command...]"
			end
		}
	end
end
