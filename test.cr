#commands = Hash(String, (Array(String), Channel(String), Channel(String) ->))
#pp commands
#proc = ->(args : Array(String), input : Channel(String), output : Channel(String)) { }
#pp proc
#def test(&block : (Array(String), Channel(String), Channel(String) ->))
#	pp block
#end
#test {|args, input, output|}
#commands["test"] = proc

test = Hash(String, (String -> String)).new
test["abc"] = ->(x : String) { x }
