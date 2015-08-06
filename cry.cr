# Cry's main file.
require "concurrent"

require "toml"

require "./src/irc/irc.cr"
require "./src/output/*"
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
		if perms.is_a? Array
			perms.each {|perm|
				perm = perm as String
				permissions.user_addgroup(user, perm)
			}
		end
	}
	if settings["aliases"]?
		settings_aliases = settings["aliases"] as Hash
		settings_aliases.each_with_index {|als, content|
			content = content as String
			parser.set_alias als, content
		}
	end
	if settings["modules"]?
		settings_modules = settings["modules"] as Hash
		loaded = settings_modules["load"] as Array
		loaded.each {|mod|
			mod = mod as String
			case mod.downcase
			when "basic"
				BasicCommands.new(parser)
			when "permissions"
				PermissionCommands.new(parser, permissions)
			when "esolangs"
				EsolangCommands.new(parser)
			when "pnacl"
				puts "loading pnacl"
				PNaCLCommands.new(settings, parser, permissions)
			end
		}
	end

	bot = IRC.new(settings_irc["server"] as String, settings_irc["port"] as Int, settings_irc["nickname"] as String, settings_irc["username"] as String, realname, ssl, password)
	chans = (settings_irc["channels"] as Array)
	chans.each {|c|
		c = c as String
		bot.join c
		#bot.msg c, "CRY ME A RIVER."
	}
	bot.run {|msg|
		Output.receivedline msg
		if /^:(.*?)!(.*?)@(.*?) PRIVMSG (.*?) :\$(.*)$/.match(msg)
			spawn {
				res = ""
				begin
					res = parser.parse($~[1], $~[4], $~[5]).to_s
				rescue e
					res = "Error: #{e.to_s}"
				end
				if res != ""
					(res + "\n").split('\n').each {|l|
						bot.msg $~[4], "@ #{l}"
					}
				end
			}
		end
	}
else
	puts "Usage: cry configfile.toml"
	exit 1
end
