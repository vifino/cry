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
				command = a.args[1..a.args.size]
				if permissions.user_hasprivilege(a.nick, "sudo")
					cmd = command[0]?
					if cmd.is_a? String
						args = command[1..a.args.size]
						raw = CommandHelper.reassembleraw(cmd, args)
						parser.call_cmd(user, a.chan, cmd, args, a.input, a.output, a.callcount, true, raw)
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
