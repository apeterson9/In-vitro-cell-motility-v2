function [fh ah] = create_printable_subplot_axes(numFigures)

        fh = figure;
        set(fh,'Units','inches','Position',[0 0 8 11]); % paper size
        borderSize = 1;
        padding = 0.25;
        netHeight = 11-borderSize*2;
        netWidth = 8-borderSize*2;
        aspectRatio = netWidth/netHeight;
        netArea = netHeight*netWidth;
        
        % Find Height Range
        % WxH >= numFigures
        % W = H*wxhRatio
        % H <= numFigures
        % wxhRatio * H^2 >= numFigures
        % H >= sqrt(numFigures/wxhRatio);
        % W >= sqrt(numFigures*wxhRatio);
        
        bH = sqrt(numFigures/aspectRatio);
        bW = sqrt(numFigures*aspectRatio);
        
        H = max(1,floor(bH));
        W = max(1,floor(bW));
        tileSize = min(H,W);
        
        tryH = floor(netHeight/tileSize);
        tryW = floor(netWidth/tileSize);
        
        if tryH*tryW < numFigures
            
        
        maxW = numFigures;
        maxH = numFigures;
        
        wRange = [minW:numFigures];
        hRange = [minH:numFigures];
        
        
        % Find Width Range
        % WxH >= numFigures
        minW = maxH/numFigures;
        maxW = 
        
        % find maximum size of each subplot
        maxPlotSize = netArea/numFigures;
        maxCols = floor(netWidth/sqrt(maxPlotSize));
        maxRows = floor(netHeight/sqrt(maxPlotSize));
        
        
        for iP = 1:numFigures
        p1 = [1 1 3 3];
        p2 = [4.25 1 3 3];
        p3 = [1 4.25 3 3];
        p4 = [4.25 4.25 3 3];
        p5 = [1 7.5 3 3];
        p6 = [4.25 7.5 3 3];
        end % for iP
        
        ah{1} = axes('Parent',fh,'Units','inches','Position',p1,'YTickLabel',[],'XTickLabel',[]);
        ah{2} = axes('Parent',fh,'Units','inches','Position',p2,'YTickLabel',[],'XTickLabel',[]);
        ah{3} = axes('Parent',fh,'Units','inches','Position',p3,'YTickLabel',[],'XTickLabel',[]);
        ah{4} = axes('Parent',fh,'Units','inches','Position',p4,'YTickLabel',[],'XTickLabel',[]);
        ah{5} = axes('Parent',fh,'Units','inches','Position',p5,'YTickLabel',[],'XTickLabel',[]);
        ah{6} = axes('Parent',fh,'Units','inches','Position',p6,'YTickLabel',[],'XTickLabel',[]);
end