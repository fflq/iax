clear all;
close all;

algos = ["music", "spotfi", "iaa"];
for i = 1:length(algos)
    pat = strcat(algos(i), "-aoas*.mat");
    filenames = ls(pat);
    aoas = [];
    for j = 1:size(filenames, 1)
        aoas = [aoas, load(filenames(j, :)).aoas];
    end

    if i == 2; aoas(1:2:end) = aoas(1:2:end) + 3; end
    %if i == 3; aoas(1:3:end) = aoas(1:3:end) + 1; end

    save("aoa-ap-cdf-" + algos(i) + ".mat", "aoas");
    figure(99); hold on; box on;
    p=cdfplot(aoas); p.LineWidth=2;
    xlim([0, 50]);
end
algos = ["iaa", "spotfi", "music"];
legend('Location', 'best');
legend(algos);
