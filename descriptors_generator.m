function descriptors = descriptors_generator(img, centers_row, centers_col, neighbor_size)
%%
%%
[max_row, max_col] = size(img);
descriptors = cell(size(centers_row), 1);
for i=1:size(centers_row)
   row = centers_row(i);
   col = centers_col(i);
   if (row-neighbor_size >= 1 && row+neighbor_size <= max_row && col-neighbor_size >= 1 && col+neighbor_size <= max_col)
        descriptors{i} = reshape(img(row-neighbor_size:row+neighbor_size, col-neighbor_size:col+neighbor_size), 1, (neighbor_size*2+1)^2);
   else
        descriptors{i} = []; %this might be problem
   end
end


