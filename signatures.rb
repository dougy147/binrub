#!/usr/bin/ruby

def build_signatures_hash(signature_table)
    'Constructs and returns a hash composed of available signatures from the magic file'
    line_index = 1
    signatures = Hash.new
    File.open(signature_table).each_line do |line|
	if (not line[0] == '#') && (not line == '\n') && (not line.tr("\n","") == "")
	    line = line.split("\t")
	    if line.length != 3
		print "WARNING: bad formatting in Signatures Table \"#{signature_table}\" (line #{line_index})\n"
		line_index+=1
		next
	    end
	    h = Hash.new
	    h["hex_signature"] = line[0].split(" ").map {|item| item.downcase}
	    h["offset"] = line[1] == "any" ? line[1] : Integer(line[1])
	    h["description"] = line[2].tr("\n","")
	    h["magic_length"] = h["hex_signature"].length
	    h["bytes"] = line[0].split(" ").map {|item| item.bytes}
	    signatures[h["hex_signature"].join] = h
	    line_index+=1
	end
    end
    if signatures.length == 0
	msg = "ERROR: no magic byte inside signatures file."
	usage(1,msg)
    end
    signatures = signatures.sort_by { |key, _| key.length }.reverse.to_h # sort by size of key (descending order)
    return signatures
end

def browse_file(file, signature_table)
    'Returns a hashmap of signatures found in file from signature table'
    signatures = build_signatures_hash(signature_table)
    block = signatures.max_by{|k,v| v["magic_length"]}
    block = block[1]["magic_length"]
    offset = 0
    after_first_byte = false
    File.open(file, 'rb') do |f|
	until f.eof?
	    matching = Hash.new
	    found = false
	    #' remove unmatched offset from signatures '
	    #if after_first_byte == false && offset > 0
	    #    signatures = signatures.select { |key,value| value["offset"] >= offset }
	    #    after_first_byte = true
	    #    block = signatures.max_by{|k,v| v["magic_length"]}
    	    #    block = block[1]["magic_length"]
	    #end

	    chunk = f.read(block).unpack("H*").join

	    ' iterate through signatures and check if they are included in the chunk '
	    chunked = 0
	    unless chunk == nil || chunk.length == 0
	        signatures.each do |key, val|
		    if key.length > chunk.length
			next
		    end
	    	    if chunk.slice(0, key.length) == key
	    		chunk = chunk.slice(key.length+1, chunk.length)
			printf "%-15s %-15s %s\n", offset, "0x%X" % offset, val["description"]
			chunked += key.length
	    		next
	    	    end
	    	end
		chunk == nil ? break : chunk = chunk.slice(1, chunk.length)
		chunked+=1
	    end
	    offset+=block
	end
    end
end
