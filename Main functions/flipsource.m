subNum = 1;
subplot(plotRows,plotCols,subNum,{@flipsource,)

function flipsource(src)
      sourceF = [200 1; 500 1]*pixUnit; % bottom (in vitro)
      line(src,[sourceF(1,1) sourceF(2,1)],[sourceF(1,2), sourceF(2,2)],'Color','r','LineWidth',3);
      