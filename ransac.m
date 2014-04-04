function [f, inlierIdx, residual] = ransac1( x,y,ransacCoef)

%[f inlierIdx] = ransac1( x,y,ransacCoef,solveHomo,calcDist )
%	Use RANdom SAmple Consensus to find a fit from X to Y.
%	X is M*n matrix including n points with dim M, Y is N*n;
%	The fit, f, and the indices of inliers, are returned.
%
%	RANSACCOEF is a struct with following fields:
%	minPtNum,iterNum,thDist,thInlrRatio
%	MINPTNUM is the minimum number of points with whom can we 
%	find a fit. For line fitting, it's 2. For homography, it's 4.
%	ITERNUM is the number of iteration, THDIST is the inlier 
%	distance threshold and ROUND(THINLRRATIO*n) is the inlier number threshold.
%
%	solveHomo is a func handle, f1 = solveHomo(x1,y1)
%	x1 is M*n1 and y1 is N*n1, n1 >= ransacCoef.minPtNum
%	f1 can be of any type.
%	calcDist is a func handle, d = calcDist(f,x1,y1)
%	It uses f returned by solveHomo, and return the distance
%	between f and the points, d is 1*n1.
%	For line fitting, it should calculate the dist between the line and the
%	points [x1;y1]; for homography, it should project x1 to y2 then
%	calculate the dist between y1 and y2.
%
% Author: 
% Bicheng Zhang  
% Department of Computer Engineering
% University of Illinois Urbana Champaign
% viczhang1990@gmail.com
%
% March 2014


minPtNum = ransacCoef.minPtNum;
iterNum = ransacCoef.iterNum;
thDist = ransacCoef.thDist;
ptNum = size(x,2);

inlrNum = zeros(1,iterNum);
fLib = cell(1,iterNum);

for p = 1:iterNum
	% 1. fit using  random points
	sampleIdx = randIndex(ptNum,minPtNum);
	f1 = solveHomo(x(:,sampleIdx),y(:,sampleIdx));
    
    %disp(det(f1));
	
	% 2. count the inliers, if more than thInlr, refit; else iterate
	dist = calcDist(f1,x,y);
    
	inlier1 = find(dist < thDist);
    %%disp(dist);
    inlrNum(p) = length(inlier1);
	if length(inlier1) < 4, continue; end
	%%fLib{p} = solveHomo(x(:,inlier1),y(:,inlier1));
    fLib{p} = f1;
end


% 3. choose the coef with the most inliers
[lalala,idx] = max(inlrNum);
%%disp(inlrNum);
%%fprintf('RANSAC: Maximum inlier number is:%d\n', lalala);
f = fLib{idx};
[dist, residual] = calcDist(f,x,y);
inlierIdx = find(dist < thDist);
	
end



function [d, residual] = calcDist(H,pts1,pts2)
%	Project PTS1 to PTS3 using H, then calcultate the distances between
%	PTS2 and PTS3
n = size(pts1,2);
pts3 = H*[pts1;ones(1,n)];
pts3 = pts3(1:2,:)./repmat(pts3(3,:),2,1);
d = sum((pts2-pts3).^2,1);

residual = sum(d)/n;
end


function H = solveHomo(pts1,pts2)
%	H is 3*3, H*[pts1(:,i);1] ~ [pts2(:,i);1], H(3,3) = 1
%	the solving method see "projective-Seitz-UWCSE.ppt"

pts1 = pts1';
pts2 = pts2';

n = size(pts1, 1);

A = zeros(2*n, 9);

for i=1:n
    k = 2*i-1;
    x1_T = [pts1(i,1), pts1(i,2), 1];
    A(k,1:3) = [0,0,0];
    A(k,4:6) = x1_T;
    A(k,7:9) = -pts2(i,2) * x1_T;
    A(k+1,1:3) = x1_T;
    A(k+1,4:6) = [0,0,0];
    A(k+1,7:9) = -pts2(i,1) * x1_T;
end

[~,~,V] = svd(A);

H = reshape(V(:,end), [3,3])';

%%H = H/H(end); %% H(3,3) = 1

end