addpath('C:/Users/flq\OneDrive/flqdata/breath/')

osts=load('breath50p20_ax2xx_40ht40he160-2.mat').sts;
sts={};
for i = 1:length(osts)
    if osts{i}.chan_width == 160
        sts{end+1} = osts{i};
        if i < 500; continue; end
        st=osts{i};
        save('C:\Users\flq\OneDrive\flqdata\paper\st210','st');
        paper_fig
        input("")
    end
end
