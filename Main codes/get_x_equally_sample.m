function x=get_x_equally_sample(ABNs,GNs)

T=[GNs;ABNs];


x=[];
for i=1:size(T,1)
    pnt=size(T{i, end},2);
    fun = @(x) mean(datasample(x, pnt, 2, 'Replace', false), 2);
    m=cellfun(fun, T(i, :), 'UniformOutput', false);
    x=[x;cat(2,m{:})];
end
