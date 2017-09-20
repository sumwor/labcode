function errorshade(x,y,h,l,c)
%takes values and plot error as shaded area

h=fill([x fliplr(x)],[h fliplr(l)],c,'LineStyle','none');