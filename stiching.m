function [stitched, inliers, residual] = stiching(left_img_rgb, right_img_rgb, harris_coe, ransac_coef, neighbor_size, putative_matches_limit, SHOW)

% STITCHING - Pair image stitching algorithm
% Usage:  [stitched, inliers, residual] = stiching(left_img_rgb, right_img_rgb, harris_coe, ransac_coef, neighbor_size, putative_matches_limit, SHOW)
% Arguments:   
%            left_img_rgb     - left image in rgb format
%            right_img_rgb     - right image in rgb format
%            harris_coe  - Harris corder detector coefficient
%                     
%            ransac_coef - Ransac coefficient
%            neighbor_size - Putative matches neighbor size
%            putative_matches_limit   - Maximum number of putative matches
%            SHOW - 1: show detail to console. 0: not show
%
% Returns:
%            stitched    - Stitched image in rgb format
%            inliers      - all inliers in [x,y] format
%            residual      - average residual of best selected putative
%                           matches
%
%
% Author: 
% Bicheng Zhang  
% Department of Computer Engineering
% University of Illinois Urbana Champaign
% viczhang1990@gmail.com
%
% March 2014



%% 1. Load all images, convert to double and to grayscale
left_img_gray = rgb2gray(left_img_rgb);
left_img_double = im2double(left_img_gray);
right_img_gray = rgb2gray(right_img_rgb);
right_img_double = im2double(right_img_gray);



%% 2. Detect feature points in both images, 
%% ** Did some trick to eleminator edge features
[l_cim, l_r, l_c] = harris(left_img_gray, harris_coe.sigma, neighbor_size+11+mod(neighbor_size+1,2), harris_coe.threshold, harris_coe.radius, harris_coe.display_result);
[r_cim, r_r, r_c] = harris(right_img_gray, harris_coe.sigma, neighbor_size+11+mod(neighbor_size+1,2), harris_coe.threshold, harris_coe.radius, harris_coe.display_result);

if SHOW == 1
    fprintf('Number of features -> [left img]:%d; [right img]:%d\n', size(l_r, 1), size(r_r, 1));
end

%% 3. Extract local neighborhoods around every keypoint and form descriptors
left_img_descriptors = descriptors_generator(left_img_double, l_r, l_c, neighbor_size);
right_img_descriptors = descriptors_generator(right_img_double, r_r, r_c, neighbor_size);


%% 4. Compute distances between every descriptor in one image and every descriptor in the other image. 
%%    You can use this code for fast computation of Euclidean distance. 
%%    Alternatively, experiment with computing normalized correlation, 
%%    or Euclidean distance after normalizing all descriptors to have zero mean and unit standard deviation. 
left_img_descriptors_len = size(left_img_descriptors, 1);
right_img_descriptors_len = size(right_img_descriptors, 1);

distance_matrix = zeros(left_img_descriptors_len*right_img_descriptors_len, 3);
n = 1;
for i=1:left_img_descriptors_len
    for j=1:right_img_descriptors_len
        left_img_descriptor = left_img_descriptors{i};
        right_img_descriptor = right_img_descriptors{j};
        normalized_left_descriptors = (left_img_descriptor - mean(left_img_descriptor(:)))/std(left_img_descriptor(:));
        normalized_right_descriptors = (right_img_descriptor - mean(right_img_descriptor(:)))/std(right_img_descriptor(:));
        dist = dist2(normalized_left_descriptors, normalized_right_descriptors);
        distance_matrix(n, :) = [dist, i, j];
        n = n + 1;
    end
end


%% 5. Select putative matches based on the matrix of pairwise descriptor distances obtained above. You can select all pairs
%%    whose descriptor distances are below a specified threshold, or select the top few hundred descriptor pairs with the smallest pairwise distances.

sorted_distance_matrix = sortrows(distance_matrix, 1);
putative_matches = sorted_distance_matrix(1:putative_matches_limit, :, :);

num_putative_matches = size(putative_matches, 1);

left_img_ptrs = zeros(num_putative_matches, 2);
right_img_ptrs = zeros(num_putative_matches, 2);

if SHOW == 1
    fprintf('Number of putative matches:%d\n', num_putative_matches);
end

for i=1:num_putative_matches
    left_img_ptr_index = putative_matches(i, 2);
    left_img_ptrs(i, :) = [l_c(left_img_ptr_index), l_r(left_img_ptr_index)];
    right_img_ptr_index = putative_matches(i, 3);
    right_img_ptrs(i, :) = [r_c(right_img_ptr_index), r_r(right_img_ptr_index)];   
end




%% 6. Run RANSAC to estimate a homography mapping one image onto the other. 
%%    Report the number of inliers and the average residual (squared distance between the 
%%    point coordinates in one image and the transformed coordinates of the matching point in the other image). 
%%    Also, display the locations of inlier matches in both images.

[H, inliers, residual] = ransac(left_img_ptrs',right_img_ptrs',ransac_coef);

inlier_num = size(inliers', 1);

if SHOW == 1
    fprintf('Number of inliers:%d, residual:%d\n', inlier_num, residual);
end

left_img_inl = zeros(inlier_num, 2);
right_img_inl = zeros(inlier_num, 2);


for i=1:inlier_num
    inlier_index = inliers(i);
    left_img_inl(i, :) = left_img_ptrs(inlier_index, :);
    right_img_inl(i, :) = right_img_ptrs(inlier_index, :);
end 


%{
figure, imagesc(left_img_rgb), axis image, colormap(gray), hold on 
plot(left_img_inl(:,2),left_img_inl(:,1),'ys'), title('left image inliers');


figure, imagesc(right_img_rgb), axis image, colormap(gray), hold on 
plot(right_img_inl(:,2),right_img_inl(:,1),'ys'), title('right image inliers');
%}
if SHOW == 1
    showMatchingPoints(left_img_rgb,right_img_rgb,left_img_inl(:,2),left_img_inl(:,1),right_img_inl(:,2),right_img_inl(:,1));
end

%% 7. Warp one image onto the other using the estimated transformation. 
%%    To do this, you will need to learn about maketform and imtransform functions.

tform = maketform('projective', H');

[lala,xdataim2t,ydataim2t]=imtransform(left_img_rgb,tform, 'nearest');


xdataout=[min(1,xdataim2t(1)) max(size(right_img_rgb,2),xdataim2t(2))];
ydataout=[min(1,ydataim2t(1)) max(size(right_img_rgb,1),ydataim2t(2))];



left_img_t=imtransform(left_img_rgb,tform,'XData',xdataout,'YData',ydataout);
right_img_t=imtransform(right_img_rgb,maketform('affine',eye(3)),'XData',xdataout,'YData',ydataout);



%% 8. Create a new image big enough to hold the panorama and composite the two images into it. 
%%    You can composite by simply averaging the pixel values where the two images overlap. 
%%    Your result should look something like this (but hopefully with a more precise alignment)

%stitched=max(right_img_t, left_img_t);
stitched = right_img_t/2 + left_img_t;





end