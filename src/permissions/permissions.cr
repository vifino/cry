# Permissions: Groups, rights and other fun stuff.
class Permissions
	alias Privileges = Array(String)
	alias Group = Array(String)
	property users
	property groups

	def initialize()
		@users = Hash(String, Group).new
		@groups = Hash(String, Privileges).new

		addgroup "admin", ["admin", "shell"]
		addgroup "sudo", ["sudo"]
	end

	# Modify groups themselves.
	def addgroup(name : String, privileges : Privileges)
		if !@groups.has_key? name
			@groups[name] = privileges
			return true
		end
		return false
	end
	def modgroup(name : String, privileges : Privileges)
		@groups[name] = privileges
	end
	def delgroup(name : String)
		if @groups.has_key? name
			@groups.delete name
			return true
		end
		return false
	end

	# Users.
	def user_addgroup(user : String, group : String)
		if !@users.has_key? user
			@users[user] = Group.new
			@users[user] << group
		else
			hasgroup = false
			@users[user].map {|g|
				hasgroup = true if g == group
			}
			if !hasgroup
				@users[user] << group
				return true
			else
				return false
			end
		end
	end
	def user_hasgroup(user : String, group : String)
		@users[user] = Group.new if !@users.has_key? user
		@users[user].each {|g|
			return true if g == group
		}
		return false
	end
	def user_delgroup(user : String, group : String)
		@users[user].delete group
	end

	def user_hasprivilege(user : String, privilege : String, checkadmin=true)
		@users[user] = Group.new if !@users.has_key? user
		@users[user].each {|g|
			if checkadmin
				return true if g == "admin"
			end
			@groups[g].each {|p|
				return true if p == privilege
			}
		}
		return false
	end
end
