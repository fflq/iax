
%set(gca, 'LooseInset', [0,0,0,0]);

aoa = -45
c=compass(cosd(90-aoa), sind(90-aoa));
c.LineWidth=6;
axis([-1,1,0,1]);
xticks([0 45 90 135]);
xticklabels({'N', 'NE', 'E', 'SE'});
yticks([0 5 10 15 20]);
yticklabels({'0', '5', '10', '15', '20'});
return;

% 创建新的图形
fig = figure;

% 在图形中创建两行一列的子图
subplot(2, 1, 1);
x1 = linspace(0, 2*pi, 100);
y1 = sin(x1);
h=plot(x1, y1); box on; hold on;
h.LineWidth=8;
title('第一个子图');

subplot(2, 1, 2);
x2 = linspace(0, 2*pi, 100);
y2 = cos(x2);
h=plot(x2, y2);box on; hold on;
h.LineWidth=5;
title('第二个子图');
