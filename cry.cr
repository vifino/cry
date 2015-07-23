# Cry's main file.
require "concurrent"

require "toml"

require "./src/irc/irc.cr"
require "./src/parser/commandparser.cr"
require "./src/permissions/permissions.cr"
require "./src/commands/*"

if ARGV[0]?
	file = File.read(ARGV[0])
	settings = TOML.parse(file)

	settings_irc = settings["irc"] as Hash
	password = nil
	if settings_irc.has_key? "password"
		password = settings_irc["server"] as String
	end
	ssl = false
	if settings_irc.has_key? "ssl"
		ssl = settings_irc["ssl"] as Bool
	end
	realname = "Cry me a river."
	if settings_irc.has_key? "realname"
		realname = settings_irc["realname"] as String
	end

	# Initialization.
	parser = CommandParser.new
	permissions = Permissions.new
	settings_permissions = settings["permissions"] as Hash
	settings_permissions.each_with_index {|user, perms|
		if perms.is_a? String
			perms.split.each {|perm|
				permissions.user_addgroup(user, perm)
			}
		elsif perms.is_a? Hash
			perms.each {|perm|
				permissions.user_addgroup(user, perm)
			}
		end
	}
	BasicCommands.new(parser)
	PermissionCommands.new(parser, permissions)
	EsolangCommands.new(parser)

	bot = IRC.new(settings_irc["server"] as String, settings_irc["port"] as Int, settings_irc["nickname"] as String, settings_irc["username"] as String, realname, ssl, password)
	chans = (settings_irc["channels"] as String).split
	chans.each {|c|
		bot.join c
		#bot.msg c, "CRY ME A RIVER."
	}
	bot.run {|msg|
		if /^:(.*?)!(.*?)@(.*?) PRIVMSG (.*?) :\$(.*)$/.match(msg)
			spawn {
				res = ""
				begin
					res = parser.parse($~[1], $~[4], $~[5]).to_s
				rescue e
					res = "Error: #{e.to_s}"
				end
				if res != ""
					($~[4]).each_line {|l|
						bot.msg l, "@ #{res}"
					}
				end
			}
		end
	}
else
	puts "Usage: cry configfile.toml"
	exit 1
end
