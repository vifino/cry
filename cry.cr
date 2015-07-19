require "./src/irc/irc.cr"
require "toml"
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

	bot = IRC.new(settings_irc["server"] as String, settings_irc["port"] as Int, settings_irc["nickname"] as String, settings_irc["username"] as String, realname, ssl, password)
	bot.join "#V"
	bot.msg "#V", "CRY ME A RIVER."
	bot.quit
else
	puts "Usage: cry configfile.toml"
	exit 1
end

