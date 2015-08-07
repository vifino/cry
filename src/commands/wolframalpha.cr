# Wolfram Alpha
require "cgi"
require "xml"
require "http"

require "../parser/commandhelper.cr"

class WolframCommands
	def initialize(settings_all, parser)
		if settings_all["wolframalpha"]?
			settings = settings_all["wolframalpha"] as Hash
			appid = settings["appid"] as String
			wa = WolframAlpha.new appid
			parser.command "wa", "query Wolfram|Alpha" {|a|
				if !a.args.empty?
					term = ""
					a.args.each {|a| term = term + a}
					term = term.strip
					doc = wa.query(term)
					base = doc.children[0]
					if base.attributes[0].content != "true" # no success
						a.output.send "Error: No success."
					elsif base.attributes[1].content != "false" # error
						a.output.send "Error: Wolfram errored."
					else
						res = WolframAlpha.parse_xml(doc)
						res.each {|k, v|
								a.output.send "#{k}: #{v[0]}\n"
						}
					end
				end
			}
		else
			raise "Need Wolfram|Alpha appid to function!"
		end
	end
end

class WolframAlpha
	@version = "v2"
	def initialize @appid : String
	end
	def query(string)
		res = HTTP::Client.exec("GET", "https://api.wolframalpha.com/"+ @version + "/query?format=plaintext&input=" + CGI.escape(string) + "&appid=" + @appid)
		body = res.body.gsub(/\\:([0-9a-z][0-9a-z][0-9a-z][0-9a-z])/) {|s| "&#x"+ s[1] +";"}
		return XML.parse(CGI.unescape(body)) # I could have cleaned up that a bit... Oh well.
	end

	def self.parse_xml(doc)
		out = Hash(String, Array(String)).new
		base = doc.children[0]

		base.children.each {|i|
			if i.is_a? XML::Node
				if !i.attributes.empty?
					title = i.attributes[0].content as String
					i.children.each {|i2|
						if !i2.attributes.empty?
							args = [] of String
							i2.children.each {|i3|
								if i3.name == "plaintext"
									if !i3.children.empty?
										args << i3.children[0].content as String
									end
								end
							}
							out[title] = args if !args.empty?
						end
					}
				end
			end
		}
		out
	end
end
