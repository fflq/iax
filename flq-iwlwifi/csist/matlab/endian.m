
classdef endian < handle

properties (Access='public')
end

methods (Access='public')
	function self = endian()
    end
end

methods (Static)
    function n = le16u(s)
        s = uint16(s);
        n = s(1)+s(2)*256;
    end

    function n = le32u(s)
        s = uint32(s);
        n = s(1)+s(2)*256+s(3)*(256^2)+s(4)*(256^3) ;
    end

    function n = le64u(s)
        s = uint64(s);
        n = uint64(le32u(s(1:4))) + uint64(le32u(s(5:8)))*(256^4) ;
    end

    %{
    %need s(nitem, comp), be=big-endian
    function r = to_uintn(s, be)
        persistent lews ;
        if isempty(lews)
            pows = 0:16-1 ;
            lews = 256 .^ pows ;
        end

        ws = lews(1:size(s,2)) ;
        if be; ws = flip(ws); end 
        r = sum(s.*ws, 2) ;
    end

    function r = uintn_to_intn(s, nbits)
        uintn = bitshift(1, nbits-1) ;
        r = s - 2*uintn .* (s>=uintn);
    end

    function [le16u,le32u, le64u] = gen_le_uintn()
        le16u = @(s) s(1)+s(2)*256 ;
        le32u = @(s) s(1)+s(2)*256+s(3)*(256^2)+s(4)*(256^3) ;
        le64u = @(s) le32u(s(1:4)) + le32u(s(5:8))*(256^4) ;
    end

    function r = le_uintn(s)
        r = to_uintn(s, false) ;
    end

    function r = le_intn(s, nbits)
        r = uintn_to_intn(le_uintn(s), nbits) ;
    end

    function r = be_uintn(s)
        r = to_uintn(s, true) ;
    end

    function r = be_intn(s, nbits)
        r = uintn_to_intn(be_uintn(s), nbits) ;
    end
    %}
end

end