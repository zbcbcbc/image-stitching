%% UIUC ECE 549 Assignment 3
%% Support stich multiple images (extra credit)
img_folder = 'pair_pitching_data/';
%img_folder = 'assignment3_data/hill/';
%img_name_list = ['1','2','3'];
img_name_list = char('uttower_1','uttower_2');
%% General paremeters
SHOW_DETAILS = 0;



%% Putative matches parameters
neighbor_size = 10;
putative_matches_limit = 50;


%% Harris code parameters
harris_coe.threshold = 5000;
harris_coe.sigma = 2.1;
harris_coe.radius = 2;
harris_coe.display_result = 0;

%% RANSAC parameters
ransac_coef.minPtNum = 4;
ransac_coef.iterNum = 10000;  
ransac_coef.thDist = 1;




total_number_img = size(img_name_list,1);
img_pool = cell(total_number_img);
for i=1:total_number_img
    img_pool{i} = imread(sprintf('%s%s', img_folder, img_name_list(i,:)),'jpg');
end

fprintf('Total number of image to stich:%d\n', total_number_img);

for total_unstitched=total_number_img:-1:2
    
    shuffler = fliplr(fullfact([total_unstitched total_unstitched]));
    shuffler(~diff(shuffler')',:) = [];
    shuffler(shuffler(:,1)>shuffler(:,2),:) = [];
    

    total_iteration = size(shuffler, 1);
    
    fprintf('Total iterations:%d\n', total_iteration);
    
    stich_rank = zeros(total_iteration, 2);
    stiched_img_pool = cell(total_iteration);

    for i=1:total_iteration
        left_img_rgb = img_pool{shuffler(i,1)};
        right_img_rgb = img_pool{shuffler(i,2)};
        [stiched_img_pool{i}, inliers, residual] = stiching(left_img_rgb, right_img_rgb, harris_coe, ransac_coef, neighbor_size,putative_matches_limit,SHOW_DETAILS);
        stich_rank(i, :) = [residual, i];
    end

    stich_rank = sortrows(stich_rank, 1);
    

    fprintf('Images [%d] [%d] will be stiched with residual:%d\n',shuffler(stich_rank(1,2),1), shuffler(stich_rank(1,2),2),stich_rank(1));

    img_pool{shuffler(stich_rank(1,2), 1)} = stiched_img_pool{stich_rank(1,2)};
    idx = [1:shuffler(stich_rank(1,2), 2)-1 shuffler(stich_rank(1,2), 2)+1:total_iteration];
    img_pool = img_pool(idx);
    
    fprintf('%d images left in img_pool\n', size(img_pool, 2));
end

figure, imshow(img_pool{1});


%{
if NUMBER_IMG == 2
    [stiched_img,~,~] = stiching(first_img_rgb, second_img_rgb, harris_coe, ransac_coef, 1);
    figure, imshow(stiched_img);
elseif NUMBER_IMG == 3
   % Test first and second
   [stiched_img_1, inliers_1, residual_1] = stiching(first_img_rgb, second_img_rgb, harris_coe, ransac_coef, neighbor_size,putative_matches_limit,0);
   % Test second and third
   %figure, imshow(stiched_img_1);
   fprintf('Image 1&2 inliers:%d, residual:%d\n', size(inliers_1,2), residual_1);
   
   [stiched_img_2, inliers_2, residual_2] = stiching(second_img_rgb, third_img_rgb, harris_coe, ransac_coef, neighbor_size,putative_matches_limit,0);
   % Test first and third
   %figure, imshow(stiched_img_2);
   fprintf('Image 2&3 inliers:%d, residual:%d\n', size(inliers_2,2), residual_2);
   
   [stiched_img_3, inliers_3, residual_3] = stiching(first_img_rgb, third_img_rgb, harris_coe, ransac_coef, neighbor_size,putative_matches_limit,0);
   %figure, imshow(stiched_img_3);
   fprintf('Image 1&3 inliers:%d, residual:%d\n', size(inliers_3,2), residual_3);

   if residual_1 <= residual_2 && residual_1 <= residual_3
       
       [stiched_img, inliers, residual] = stiching(stiched_img_1, third_img_rgb,  harris_coe, ransac_coef, neighbor_size,putative_matches_limit,SHOW_DETAILS);
       fprintf('Image 1&2 are selected, inliers: %d, residual:%d\n', size(inliers, 2), residual);
   elseif residual_2 <= residual_1 && residual_2 <= residual_3
        
       [stiched_img, inliers, residual] = stiching(first_img_rgb, stiched_img_2,  harris_coe, ransac_coef, neighbor_size,putative_matches_limit,SHOW_DETAILS);
       fprintf('Image 2&3 are selected, inliers: %d, residual:%d\n', size(inliers, 2), residual);
   else
       [stiched_img, inliers, residual] = stiching(stiched_img_3, second_img_rgb,  harris_coe, ransac_coef, neighbor_size,putative_matches_limit,SHOW_DETAILS);
       fprintf('Image 1&3 are selected, inliers: %d, residual:%d\n', size(inliers, 2), residual);
   end   
   
   %figure, imshow(stiched_img_1);
   %figure, imshow(stiched_img_2);
   %figure, imshow(stiched_img_3);
   figure, imshow(stiched_img);
end


%}


