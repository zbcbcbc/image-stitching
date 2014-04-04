%% Image Stitching Algorithm
%% Author: Bicheng Zhang
%% Support stich multiple images
%% Parameters can be tuned for best performance

%% Please specify image folder and image names
img_folder = 'pair_pitching_data/';
img_name_list = char('uttower_1','uttower_2');


%% General paremeters
SHOW_DETAILS = 0; % Show inliers in plots, ransac algorithm info


%% Putative matches parameters
neighbor_size = 10; % Neihbor size used in putative matches
putative_matches_limit = 50; % Number of putative matches selected


%% Harris code parameters
harris_coe.threshold = 5000; % Feature point threshold
harris_coe.sigma = 2.1; % Sigma
harris_coe.radius = 2; % Feature point radius
harris_coe.display_result = 0; % Display features points 

%% RANSAC parameters
ransac_coef.minPtNum = 4; % Ransac number of putative matches selected in each iteration
ransac_coef.iterNum = 10000;  % Number of total iteration
ransac_coef.thDist = 1; % Ransac inlier distance




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


end


