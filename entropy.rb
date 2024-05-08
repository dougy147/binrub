#!/usr/bin/ruby

def shannon_entropy_file(file, block_size = 1024, data_points = 2048, trigger_high = 0.95, trigger_low = 0.85)
    'Returns an entropy value for each block, and prints by default when raising or falling'
    entropy_array = []
    file_size = File.size?(file)

    data_points = 2 * block_size

    block_size = file_size / data_points
    block_size = block_size + ((1024 - block_size) % 1024)

    # Ensure block_size is greater than 0 (in case of small files)
    if block_size <= 0
	block_size = file_size
    end
    blocks = file_size / block_size

    last_edge = ""
    trigger = true
    in_block = Hash.new
    remaining_size = file_size
    original_block_size = block_size # in case block_size is changed during computation, serves to compute offset

    File.open(file, 'rb') do |f| # rb with b standing for binary file
	until f.eof?
	    (0..blocks).each do |block|
    	        entropy = 0
		if remaining_size < block_size
		    block_size = remaining_size
		end
		if block_size <= 0
		    break
		end
		slice = f.read(block_size)
		remaining_size -= block_size

    	    	(0..255).each { |x| in_block[x] = 0 }

		slice.each_byte {|b| in_block[b] += 1}

    	    	(0..255).each do |x|
    	            px = in_block[x].to_f / block_size
    	    	    if px > 0
    	    	        entropy -= px * Math.log2(px)
    	    	    end
    	    	end

    	        entropy /= 8

    	        msg = ""
    	        if (last_edge == "low") && entropy > trigger_low
    	            trigger = true
    	        elsif (last_edge == "high") && entropy < trigger_high
    	            trigger = true
    	        end

    	        if trigger && entropy >= trigger_high
    	            last_edge = "high"
    	            trigger = false
    	            msg = "Rising entropy edge (#{entropy})"
    	        elsif trigger && entropy <= trigger_low
    	            last_edge = "low"
    	            trigger = false
    	            msg = "Falling entropy edge (#{entropy})"
    	        end

    	        if msg != ""
		    printf "%-15s %-15s %s\n", block * original_block_size, "0x%X" % (block * original_block_size), msg
    	        end
    	        entropy_array.append(entropy)
    	    end
	    break
	end
    end

    # plot entropy in terminal
    begin
	require 'unicode_plot'
	puts
    	x=*(1..entropy_array.length)
    	y=entropy_array
    	UnicodePlot.lineplot(x,y, title: "Entropy (block size = #{original_block_size})").render
    rescue
	puts "WARNING: 'unicode_plot' library not found, no graph will be plotted. Use 'gem install unicode_plot' to install."
    end

    return entropy_array
end # shannon_entropy_file end
