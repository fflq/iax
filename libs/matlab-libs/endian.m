
classdef endian < handle

properties (Access='public')
end

methods (Access='public')
	%function self = endian()
    %end
end

methods (Static)
    function n = le16u(s)
        s = uint16(s);
        n = s(1)+s(2)*256;
    end

    function n = le32u(s)
        s = uint32(s);
        %n = s(1)+s(2)*256+s(3)*(256^2)+s(4)*(256^3) ;
        n = uint32(endian.le16u(s(1:2))) + uint32(endian.le16u(s(3:4)))*(256^2);
    end

    function n = le64u(s)
        s = uint64(s);
        n = uint64(endian.le32u(s(1:4))) + uint64(endian.le32u(s(5:8)))*(256^4) ;
    end

    function n = le16i(s)
        n = typecast(endian.le16u(s), 'int16');
    end

    function n = le32i(s)
        n = typecast(endian.le32u(s), 'int32');
    end

    function n = le64i(s)
        n = typecast(endian.le64u(s), 'int64');
    end

    
    function n = be16u(s)
        n = swapbytes(endian.le16u(s));
    end

    function n = be32u(s)
        n = swapbytes(endian.le32u(s));
    end

    function n = be64u(s)
        n = swapbytes(endian.le64u(s));
    end

    function n = be16i(s)
        n = swapbytes(endian.le16i(s));
    end

    function n = be32i(s)
        n = swapbytes(endian.le32i(s));
    end

    function n = be64i(s)
        n = swapbytes(endian.le64i(s));
    end


    %{
	function r = leuint(s)
        s = uint64(s);
		r = uint64(0);
		m = uint64(1);
		for i = 1:length(s)
			r = r + s(i)*m;
			m = m*256;
		end
	end

	function r = leint(s)
        r = typecast(endian.leuint(s), 'int64');
    end
    %}

    %{
	function r = leuint(s)
		r = 0;
		m = 1;
		for i = 1:length(s)
			r = r + s(i)*m;
			m = m*256;
		end
	end

	function r = leint(s)
		r = endian.leuint(s) ;
		nbit = length(s)*8 ;
		highest_bit = bitshift(1, nbit-1) ;
		if bitand(r, highest_bit)
			r = r - bitshift(1, nbit) ;
		end
	end
    %}

end

end