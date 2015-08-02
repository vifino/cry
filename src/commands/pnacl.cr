# PNaCL runner stuff thingie.
#
# Make sure to set the pnacl settings to the correct values.
require "tempfile"
class PNaCLCommands
	def initialize(settings_all, parser, perms)
		if settings_all["pnacl"]?
			settings = settings_all["pnacl"] as Hash

			@pnacl_clang = settings["pnacl_clang"] as String
			@pnacl_finalize = settings["pnacl_finalize"] as String
			@pnacl_translate = settings["pnacl_translate"] as String
			@pnacl_arch = settings["arch"] as String
			@sel_ldr = settings["sel_ldr"] as String

			pnacl = PNaCL.new(@pnacl_clang, @pnacl_finalize, @pnacl_translate, @pnacl_arch, @sel_ldr)
			parser.command "cc", "compile c code" {|a|
				if perms.user_hasprivilege(a.nick, "pnacl")
					code = CommandHelper.readall(a.input)
					return if code == ""
					o = BufferedChannel(String).new
					Thread.new {
						args_cmd = ["-x", "c", "-"]
						a.args.each {|arg|
							args_cmd << arg
						}
						args_cmd << "-o"
						out_tmp = Tempfile.new "cry_pnacl"
						out_tmp.close
						args_cmd << out_tmp.path
						status = Process.run("#{@pnacl_clang}", args: args_cmd, output: true, input: code)
						if status.success?
							nexepath = "#{out_tmp.path}.nexe"
							pp out_tmp.path
							pp nexepath
							pnacl.pnacl_finalize(out_tmp.path)
							pnacl.translate(out_tmp.path, nexepath)
							File.delete(out_tmp.path)
							o.send pnacl.sel_ldr(nexepath)
							File.delete(nexepath)
						else
							o.send "Error: pnacl-clang errored:\n#{status.output.not_nil!}"
						end
						o.close
					}
					CommandHelper.pipe(o, a.output)
				else
					a.output.send "Insufficient permissions. (pnacl)"
				end
			}
		end
	end
end
class PNaCL
	property pnacl_clang
	property pnacl_finalize
	property pnacl_translate
	property pnacl_arch
	property sel_ldr

	def initialize(@pnacl_clang, @pnacl_finalize, @pnacl_translate, @pnacl_arch, @sel_ldr)
	end

	def pnacl_cc(source : String, mktemp : Bool, args=nil : Array(String)?)
		args_cmd = ["-x", "c", "-"]
		if args.is_a? Array
			args.each {|arg|
				args_cmd << arg
			}
		end
		args_cmd << "-o"
		if mktemp
			out = Tempfile.new "cry_pnacl_clang_out"
			out.close
			out.unlink
			args_cmd << out.path
		else
			args_cmd << "-"
		end
		status = Process.run("#{@pnacl_clang}", args: args_cmd, output: true, input: source)
		if mktemp
			return status.output, out
		else
			return status.output, nil
		end
	end

	def pnacl_finalize(file : String)
		`#{@pnacl_finalize} #{file}`
	end
	def pnacl_finalize(file : IO)
		`#{@pnacl_finalize} #{file.path}`
	end

	def translate(input : String, output : String)
		`#{@pnacl_translate} #{input} -arch #{@pnacl_arch} -o #{output}`
	end
	def translate(input : IO, output : IO)
		`#{@pnacl_translate} #{input.path} -arch #{@pnacl_arch} -o #{output.path}`
	end

	def sel_ldr(file : IO)
		`#{@sel_ldr} #{file.path}`
	end
	def sel_ldr(string : String, ispath=true)
		if ispath
			`#{@sel_ldr} #{string}`
		else
			tmp = Tempfile.open "cry_pnacl_sel_ldr" {|f|
				f.print string
			}
			output = sel_ldr tmp
			tmp.delete
			output
		end
	end

	private def tmpname
		"/tmp/cry_#{Process.pid}_pnacl_#{Time.new.iso8601(2)}_#{Math.random()}".gsub(/\s+/, "_")
	end
end
