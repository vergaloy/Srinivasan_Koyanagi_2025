function [D,n]=random_downsample_GNs(GNs,nABNs,nGNs)

n=sum(nABNs);

D=[GNs,repelem([1,2,3],nGNs)'];

D=datasample(D,n,1,'Replace',false);

n=[sum(D(:,end)==1),sum(D(:,end)==2),sum(D(:,end)==3)];
D=[D(D(:,end)==1,1:end-1);D(D(:,end)==2,1:end-1);D(D(:,end)==3,1:end-1)];