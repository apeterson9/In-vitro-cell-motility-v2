function R = quantify_pauses(allData)

% This function assumes that you have already compiled and processed the
% data

warnNum = 0;
scData = allData;
cellIDs = unique(scData(:,1),'stable');

% Pull out ct axis length, segment class and confinement radius
for iCell = 1:length(cellIDs)
    cellIdx = find(scData(:,1) == cellIDs(iCell));
    if length(cellIdx) > 10 % arbitrary track length to exclude short tracks
        temp = scData(cellIdx,:);
        % first I must calculate the distance gained for each
        % step
        % Defining pause as 1 or more consecutive steps with a
        % value of <1
        for iStep = 2:size(temp,1)
            d(iStep) = pdist([temp(iStep,3),temp(iStep,4);temp(iStep-1,3),temp(iStep-1,4)]) <1;
        end % for iStep
        
        % from here, I calculate the number of pauses
        p = find(d == 1);
        
        [n r] = findConsecutiveNums(p);
        
        if ~isempty(r)
            r2 = r(:,2)-r(:,1);
            r = r(r2>0,:);
            
            numPause = size(r,1);
            duration = nanmean(r(:,2)-r(:,1));
            
        else
            numPause = 0;
            duration = nan;
        end
        pauseData(iCell,1) = numPause;
        pauseData(iCell,2) = duration;
        
        clear numPause
        clear duration
        clear d
        clear p
        clear r
        clear r2
    else
        pauseData(iCell,1) = nan;
        pauseData(iCell,2) = nan;
        
    end % if length
end % for iCell
slidePause = [slidePause; pauseData];
end % for iSlide
repPause{iDir} = slidePause;
end % for iDir
groupPause{iGroup} = repPause;
clear repPause
end % for iGroup

else % is empty datFiles
    warning('\nNo processed data found for: %s...\nThis well will not be processed!',dirs{iDir});
    R{iDir,2} = 'Failed';
    end % isempty datFiles
    
    end % function
    
    
    %% Plot pause data for rescue experiments
    
    
    for iGroup = 1:length(Groups)
        dat = groupPause{iGroup};
        X = [];
        x = [];
        G = [];
        for iDat = 1:size(dat,2)
            G = [G; iGroup];
            num = nanmean(groupPause{iGroup}{iDat}(:,2));
            X = [X; num];
            dur = [nanmean(groupPause{iGroup}{iDat}(:,1))];
            x = [x; dur];
        end % for iDat
        
        subplot(1,2,1)
        scatter(G,X,'filled')
        hold on
        set(gca,'XLim',[0.5 4.5])
        subplot(1,2,2)
        scatter(G,x,'filled')
        set(gca,'XLim',[0.5 4.5])
        hold on
    end
    
    hold off
    
    %% cmap
    
    cMap = [0.384313725490196   0.478431372549020   0.615686274509804;
        0.776470588235294   0.176470588235294   0.258823529411765;
        0.403921568627451   0.784313725490196   1.000000000000000;
        0.011764705882353   0.733333333333333   0.521568627450980;
        0.996078431372549   0.701960784313725                   0;
        0.854901960784314   0.196078431372549   0.529411764705882;
        0.392156862745098   0.337254901960784   0.717647058823529;
        0   0.188235294117647   0.396078431372549;
        0.600000000000000   0.600000000000000   0.800000000000000;
        1.000000000000000   0.439215686274510   0.203921568627451;
        0.921568627450980   1.000000000000000   0.050980392156863;
        0.901960784313726   0.501960784313725   0.439215686274510;
        0.662745098039216   0.698039215686274   0.764705882352941;
        0.784313725490196   0.541176470588235   0.396078431372549;
        0.901960784313726   0.745098039215686   0.541176470588235;
        1.000000000000000   0.717647058823529   0.835294117647059;
        0.800000000000000   1.000000000000000                   0];
    
    %% Plot average pause number and duration for each group
    conds = {'CTL','KO','OE','RESC'};
    stims = {'fMLF'};
    
    
    for iStim = 1:length(stims)
        
        for iCond = 1:length(conds)
            X = [];
            G = [];
            x = [];
            groupIdx = find(contains(Groups(:),conds{iCond}));
            
            
            stimID = find(contains(Groups(groupIdx),stims{iStim}));
            stimIdx = groupIdx(stimID);
            
            n = length(groupPause{stimIdx});
            
            for iN = 1:n
                G = [G; iCond];
                num = nanmean(groupPause{stimIdx}{iN}(:,2));
                X = [X; num];
                dur = [nanmean(groupPause{stimIdx}{iN}(:,1))];
                x = [x; dur];
                
                
                if iCond == 2
                    subplot(2,3,iCond)
                    hold on
                    scatter(iCond,num,'filled','MarkerFaceColor',cMap(iN,:));
                    set(gca,'XLim',[0.5 2.5],'YLim',[1.4 2.8])
                    
                    subplot(2,3,3+iCond)
                    hold on
                    scatter(iCond,dur,'filled','MarkerFaceColor',cMap(iN,:));
                    set(gca,'XLim',[0.5 2.5],'YLim',[2 6])
                    
                else
                    subplot(2,3,iCond)
                    hold on
                    scatter(iCond,num,'filled','MarkerFaceColor',cMap(iN,:));
                    set(gca,'XLim',[0.5 2.5],'YLim',[1.4 2.8])
                    
                    subplot(2,3,3+iCond)
                    hold on
                    scatter(iCond,dur,'filled','MarkerFaceColor',cMap(iN,:));
                    set(gca,'XLim',[0.5 2.5],'YLim',[2 6])
                end
            end
            
            
            if iCond ==2
                %             G = G+0.15;
                %             subplot(1,2,1)
                %             boxplot(X,G)
                % %
                % %
                %             subplot(2,3,iStim)
                %             boxplot(X, G)
                %             hold on
                %
                %             subplot(2,3,3+iStim)
                %             boxplot(x, G)
                %             hold on
                
                numPauseKO{iStim} = X;
                durPauseKO{iStim} = x;
                
            else
                %          G = G-0.15;
                %             subplot(1,2,1)
                %             boxplot(X,G)
                %             subplot(2,3,iStim)
                %             boxplot(X, G)
                %             hold on
                %
                %             subplot(2,3,3+iStim)
                %             boxplot(x, G)
                %             hold on
                
                numPauseCTL{iStim} = X;
                durPauseCTL{iStim} = x;
            end
            
        end % for iStim
        
    end
    
    hold off
    
    %%
    
    iStim = 3;
    
    
    [a b] = kstest2(numPauseCTL{iStim},numPauseKO{iStim});
    [c d] = kstest2(durPauseCTL{iStim},durPauseKO{iStim});
    
    [a c b d]
    
    
    %%
    
    day = 1;
    dayIdx = find(agg{:,2} == day);
    
    
    c = find(agg{dayIdx,4} == 'Control');
    condIdx = dayIdx(c);
    
    ko = find(agg{dayIdx,4} == 'Arpc1b');
    koIdx = dayIdx(ko);
    
    
    met = 6
    [f x] = ksdensity(agg{condIdx,met});
    plot(x,f,'-');
    hold on
    [f x] = ksdensity(agg{koIdx,met});
    plot(x,f,'--')
    title(agg.Properties.VariableNames{met})
    
    legend('Conrol','Arpc1b')
    %% Make comparisons of pause number
    stims = {'fMLF 1uM','C5a 3uM','C5a 30uM'};
    
    
    for iStim = 1:length(stims)
        idxStim = find(agg{:,5} == stims{iStim})
        
        conIdx = find(agg{idxStim,4} == 'Control');
        conIdx = idxStim(conIdx);
        
        koIdx = find(agg{idxStim,4} == 'Arpc1b');
        koIdx = idxStim(koIdx);
        
        numPause{iStim}
        
    end % iStim
    
    
    %%
    cellNum = 24
    cellIdx = find(dat{:,1} == cellNum);
    
    track_i = dat{cellIdx,[3:4 12]};
    
    colPicker = [0 0 1; 0 0.5 1; 1 0 0.5]
    
    for i = 1:length(track_i)-1
        x = track_i(i:i+1,1);
        y = track_i(i:i+1,2);
        col = colPicker(track_i(i,3),:);
        plot(x,y,'Color',col,'LineWidth',3);
        hold on
        
    end
    
    end % function
