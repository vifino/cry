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
			parser.set_alias als, content, true
		}
	end
	if settings["modules"]?
		settings_modules = settings["modules"] as Hash
		loaded = settings_modules["load"] as Array
		loaded.each {|mod|
			mod = mod as String
			case mod.downcase
			when "basic"
				BasicCommands.new(parser, permissions)
			when "permissions"
				PermissionCommands.new(parser, permissions)
			when "esolangs"
				EsolangCommands.new(parser, permissions)
			when "pnacl"
				PNaCLCommands.new(settings, parser, permissions)
			when "wolframalpha"
				WolframCommands.new(settings, parser)
			when "tape"
				TapeCommands.new(parser)
			when "mathomatic"
				MathomaticCommands.new(parser)
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
			nick = $~[1]
			chan = $~[4]
			line = $~[5]
			spawn {
				res = ""
				begin
					if /^#(.*)$/.match chan # Channel
						res = parser.parse(nick, chan, line).to_s
						if !res.empty?
							(res + "\n").split('\n').each {|l|
								bot.msg chan, "@ #{l}" if !l.strip.empty?
							}
						end
					else # PM
						res = parser.parse(nick, nick, line).to_s
						if !res.empty?
							(res + "\n").split('\n').each {|l|
								bot.msg nick, "@ #{l}" if !l.strip.empty?
							}
						end
					end
				rescue e
					res = "Error: #{e.to_s}"
				end
			}
		end
	}
else
	puts "Usage: cry configfile.toml"
	exit 1
end
