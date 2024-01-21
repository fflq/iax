server = tcpserver("localhost",7120,"ConnectionChangedFcn",@connectionFcn)
while true
    111
    pause;
end

function connectionFcn(src,~)
if src.Connected
   disp("This message is sent by the server after accepting the client connection request.")
else
   disp("Client has disconnected.")
end
end
