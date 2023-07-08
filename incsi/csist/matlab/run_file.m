%clear ; close all; clc;
clear all ;
addpath('./csilibs') ;

%a = load("./data2/test_file.mat");
%[aoas, tofs] = spotfi(a.csi_traces, gs().envs, 1) 


tic
dats=["2m-30.dat","2m-60.dat","2m-90-5.dat","2m-120-5.dat","2m-150-5.dat",...
    "3m-45.dat","4m-45.dat","csi.dat"];
%run_from_file("./data/"+dats(1), gs().envs, -1);
run_from_file("./data/"+dats(1), gs().envs, 1);
toc
return ;
for i = 1:min(2,length(dats))
    fprintf("****** dats %d\n", i);
    run_from_file("./data/"+dats(i), gs().envs, i);
end


function aoas = run_from_file(filepath, envs, streamid)
    csi_traces = read_bf_file(filepath);
    [aoas, tofs] = spotfi(csi_traces(1:100), envs, streamid) ;
    %[tofs*1e9, aoas]
    %[aoas, tofs] = spotfi(csi_traces(24:25), envs, streamid) 
    %[aoas, tofs] = spotfi(csi_traces, envs, streamid) ;
    %[aoas, tofs*1e9]
    %sfd = get_tcpclient(nets);
    %for i=1:length(aoas)
    %    aoa_send(sfd, -aoas(i));
    %end
end

