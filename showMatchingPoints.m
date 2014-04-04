function dispImage = showMatchingPoints(image1, image2, x1, y1, x2, y2)
% Author: 
% Bicheng Zhang  
% Department of Computer Engineering
% University of Illinois Urbana Champaign
% viczhang1990@gmail.com
%
% March 2014

    [h1, w1, d] = size(image1);
    [h2, w2, ~] = size(image2);
    
    
    
    dispImage = zeros(max(h1, h2), w1+w2, d);
    
    dispImage(1:h1,1:w1,:) = image1;
    dispImage(1:h2,w1+1:w2+w1,:) = image2;
    
    
    
    figure, imshow(uint8(dispImage));
    
    hold on;
    
    for index = 1:numel(x1)
        plot([y1(index), y2(index)+w1], [x1(index), x2(index)], '-ro', 'LineWidth', 2,  'MarkerSize',8, 'MarkerFaceColor', 'g' );
    end
    
    
end

