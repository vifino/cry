# PNaCL runner stuff thingie.
#
# Make sure to set the pnacl settings to the correct values.
require "tempfile"
class PNaCLCommands
	def initialize(settings_all, parser)
		if settings_all["pnacl"]?
			pnacl = PNaCL.new(settings_all)
			parser.command "pnacl-cc", "compile c code to pnacl pexe" {|a|
				code = CommandHelper.readall(a.input)
				ary = pnacl.pnacl_cc(code, true, [] of String)
				p ary
				#s = ary[0]
				#tmp = ary[1]
				#if s.success?
				#	a.output.send tmp.read
				#	tmp.unlink
				#else
				#	a.output.send "Error: pnacl-cc errored:\n#{s.output.not_nil!}"
				#	tmp.unlink
				#end
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

	def initialize(settings_all)
		if settings_all["pnacl"]?
			settings = settings_all["pnacl"] as Hash

			@pnacl_clang = settings["pnacl-clang"] as String
			@pnacl_finalize = settings["pnacl-finalize"] as String
			@pnacl_translate = settings["pnacl-translate"] as String
			@pnacl_arch = settings["arch"] as String
			@sel_ldr = settings["sel_ldr"] as String
		end
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
			args_cmd << out.path
		else
			args_cmd << "-"
		end
		status = Process.run("#{@pnacl_clang}", args_cmd, true, source)
		if mktemp
			return [status, out]
		else
			return [status, nil]
		end
	end

	def pnacl_finalize(file : IO)
		`#{@pnacl_finalize} #{file.path}`
	end

	def translate(input : IO, output : String)
		`#{@pnacl_translate} #{file.path} -arch #{@pnacl_arch} -o #{output}`
	end
	def translate(input : IO, output : IO)
		`#{@pnacl_translate} #{file.path} -arch #{@pnacl_arch} -o #{output.path}`
	end

	def sel_ldr(file : IO)
		`#{@sel_ldr} #{file.path}`
	end
	def sel_ldr(string : String)
		tmp = Tempfile.open "cry_pnacl_sel_ldr" {|f|
			f.write string
		}
		sel_ldr tmp
		tmp.delete
	end

	private def tmpname
		"/tmp/cry_#{Process.pid}_pnacl_#{Time.new.iso8601(2)}_#{Math.random()}".gsub(/\s+/, "_")
	end
end
