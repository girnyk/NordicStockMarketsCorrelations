clear; close all; clc;

% Go two levels up from current folder
base = fileparts(pwd);

% Add all subfolders of that folder to path
addpath(genpath(base));

% Set dir paths
pathDirScript = pwd;
pathDirFuncs = [pathDirScript, '/functions/'];
pathDirFigs = [pathDirScript, '/../figures/'];
pathDirTabs = [pathDirScript, '/../tables/'];
pathDirDataClean = [pathDirScript, '/../data_clean/'];

% Init cases and switches
marketCities = {};
portfolioMethods = {};
suffixCase = '';
generateDescrStatsTab = 0;
generateEigEvoFig = 0;
generateStdEigDynamicsFig = 0;
generateCrossMarketRelationsFig = 0;
generateOlsEigenbetasTab = 0;
generateCrisisDetectionFig = 0;
generateCumReturnsFig = 0;
generatePerfStatsTab = 0;
generateExposureSweepFig = 0;
resaveTabs = 0;
resaveFigs = 0;
gamma1Vals = 0.3;
gamma2Vals = 0.2;

% #########################################################################
% CHOOSE a visual to generate (uncomment a single case at a time)
% #########################################################################

% % Table 1. Descriptive statistics of daily log-returns for the Nordic equity markets considered in the analysis
% marketCities = {'STOCKHOLM', 'COPENHAGEN', 'HELSINKI'};
% suffixCase = 'NORDICS';
% generateDescrStatsTab = 1;
% resaveTabs = 1;
% fprintf('Compute descriptive statistics of daily log-returns... \n')

% % Figure 1. Time evolution of the four largest eigenvalues of the rolling log-return correlation matrix for the Nordic equity markets
% marketCities = {'STOCKHOLM', 'COPENHAGEN', 'HELSINKI'};
% suffixCase = 'NORDICS';
% generateEigEvoFig = 1;
% resaveFigs = 1;
% fprintf('Compute time evolution of the largest eigenvalues... \n')

% % Figure 2. Standardized dynamics of the first and second eigenvalues of the rolling log-return correlation matrix
% marketCities = {'STOCKHOLM', 'COPENHAGEN', 'HELSINKI'};
% suffixCase = 'NORDICS';
% generateStdEigDynamicsFig = 1;
% resaveFigs = 1;
% fprintf('Compute standardized dynamics of the largest eigenvalues... \n')

% % Figure 3. Cross-market relations in the standardized largest eigenvalues of the rolling log-return correlation matrix
% marketCities = {'ALL_NORDICS', 'STOCKHOLM', 'COPENHAGEN', 'HELSINKI', 'FRANKFURT', 'MADRID', 'MUMBAI', 'SAO_PAULO', 'MEXICO'};
% suffixCase = 'ALL_VS_NORDICS';
% generateCrossMarketRelationsFig = 1;
% resaveFigs = 1;
% fprintf('Compute standardized dynamics of the largest eigenvalues... \n')

% % Table 2. OLS regressions of market returns on the returns of the leading correlation-based eigenportfolios
% marketCities = {'STOCKHOLM', 'COPENHAGEN', 'HELSINKI'};
% suffixCase = 'NORDICS';
% generateOlsEigenbetasTab = 1;
% resaveTabs = 1;
% fprintf('Compute OLS regressions of market returns on eigenportfolio returns... \n')

% % Figure 4. Market regime classification based on the eigenvalue-ratio crisis indicator
% marketCities = {'ALL_NORDICS'};
% suffixCase = 'NORDICS_AGG';
% generateCrisisDetectionFig = 1;
% resaveFigs = 1;
% fprintf('Compute eigenvalue-ratio crisis indicator... \n')

% % Figure 5. Cumulative returns of the portfolio strategies under consideration
% marketCities = {'STOCKHOLM', 'COPENHAGEN', 'HELSINKI'};
% portfolioMethods = {'EQUAL_WEIGHTS', 'FIRST_EIGENPORTFOLIO', 'MIN_VAR_MARKOWITZ', 'MIN_VAR_CONSTRAINED'};
% suffixCase = 'NORDICS';
% generateCumReturnsFig = 1;
% resaveFigs = 1;
% fprintf('Compute cumulative returns of portfolios... \n')

% % Table 3. Summary performance and risk statistics for the portfolio strategies under consideration
% marketCities = {'STOCKHOLM', 'COPENHAGEN', 'HELSINKI'};
% portfolioMethods = {'EQUAL_WEIGHTS', 'FIRST_EIGENPORTFOLIO', 'MIN_VAR_MARKOWITZ', 'MIN_VAR_CONSTRAINED'};
% suffixCase = 'NORDICS';
% generatePerfStatsTab = 1;
% resaveTabs = 1;
% fprintf('Compute risk-adjusted performance of portfolios... \n')

% Figure 6. Sensitivity analysis of the crisis-period exposure thresholds
marketCities = {'STOCKHOLM', 'COPENHAGEN', 'HELSINKI'};
portfolioMethods = {'EQUAL_WEIGHTS', 'MIN_VAR_MARKOWITZ', 'MIN_VAR_CONSTRAINED'};
suffixCase = 'NORDICS';
% gamma1Vals = 0.1:0.025:0.9;
% gamma2Vals = 0.1:0.025:0.9;
gamma1Vals = 0.1:0.2:0.9;
gamma2Vals = 0.1:0.2:0.9;
generateExposureSweepFig = 1;
resaveFigs = 1;
fprintf('Sweep crisis-period exposure thresholds... \n')

% #########################################################################

nMarkets = numel(marketCities);
nMethods = numel(portfolioMethods);

% Set RNG seed for reproducibility
rng(251231);

% Set params
nDaysCrisisIndicatorSmoothing = 10; % Two weeks rolling window smootihng
stepSize = 5; % One week rolling window step
windowSize = 252;% One year of trades window
thresholdCrisis = 0; % Threshold for eigenvalue-ratio indicator to detect crisis
shrinkageDensity = 0.1; % Degree of Ledoit-Wolf shrinkage

% Time horizon
startDate = datetime('2006-01-01');
endDate = datetime('2025-09-29');

% Study results
perfResultsStruct = struct();

% Init struct for eigenvalues
lambdasStruct = struct();
lambdasStruct.lambdasTab = cell(1, numel(marketCities));

% Init table for descriptive stats
if generateDescrStatsTab == 1
  descrStatsTab = table([], [], [], [], [], [], [], [], [], ...
    'VariableNames', {'Index', 'Stocks', 'Days', 'Mean', 'StdDev', 'Skewness', 'Kurtosis', 'Min', 'Max'});
end

% Init table for OLS regressions on eigenportfolio returns
if generateOlsEigenbetasTab == 1
  olsRegEigenbetasTab = table([], [], [], [], [], ...
    'VariableNames', {'Index', 'Eigenvalue', 'Beta', 'Rsquare', 'PValue'});
  olsRegEigenbetasRows = {};
end

% Init table for portfolio performance results
if generatePerfStatsTab == 1
  perfStatsTab = table([], [], [], [], [], [], [], ...
    'VariableNames', {'Index', 'Method', 'Mean', 'Vol', 'Sharpe', 'Sortino', 'Treynor'});
  perfStatsRows = {};
end

% Loop over markets
marketIndex = {};
for iMarket = 1:nMarkets

  % Set market params
  if strcmp(marketCities{iMarket}, 'STOCKHOLM')
    marketIndex{iMarket} = 'OMXS30';
    lambdasStruct.lineColor{iMarket} = 'deepskyblue';
    lambdasStruct.lineWidth{iMarket} = 1;
    lambdasStruct.lineSpec{iMarket} = '-';
  elseif strcmp(marketCities{iMarket}, 'COPENHAGEN')
    marketIndex{iMarket} = 'OMXC20';
    lambdasStruct.lineColor{iMarket} = 'red';
    lambdasStruct.lineWidth{iMarket} = 1;
    lambdasStruct.lineSpec{iMarket} = '-';
  elseif strcmp(marketCities{iMarket}, 'HELSINKI')
    marketIndex{iMarket} = 'OMXH25';
    lambdasStruct.lineColor{iMarket} = 'blue';
    lambdasStruct.lineWidth{iMarket} = 1;
    lambdasStruct.lineSpec{iMarket} = '-';
  elseif strcmp(marketCities{iMarket}, 'ALL_NORDICS')
    marketIndex{iMarket} = 'Nordics';
    lambdasStruct.lineColor{iMarket} = 'black';
    lambdasStruct.lineWidth{iMarket} = 2;
    lambdasStruct.lineSpec{iMarket} = '-';
  elseif strcmp(marketCities{iMarket}, 'FRANKFURT')
    marketIndex{iMarket} = 'DAX40';
    lambdasStruct.lineColor{iMarket} = 'black';
    lambdasStruct.lineWidth{iMarket} = 0.75;
    lambdasStruct.lineSpec{iMarket} = '--';
  elseif strcmp(marketCities{iMarket}, 'MADRID')
    marketIndex{iMarket} = 'IBEX35';
    lambdasStruct.lineColor{iMarket} = 'red';
    lambdasStruct.lineWidth{iMarket} = 0.75;
    lambdasStruct.lineSpec{iMarket} = '--';
  elseif strcmp(marketCities{iMarket}, 'MEXICO')
    marketIndex{iMarket} = 'IPC';
    lambdasStruct.lineColor{iMarket} = 'red';
    lambdasStruct.lineWidth{iMarket} = 1.5;
    lambdasStruct.lineSpec{iMarket} = ':';
  elseif strcmp(marketCities{iMarket}, 'MUMBAI')
    marketIndex{iMarket} = 'NIFTY';
    lambdasStruct.lineColor{iMarket} = 'purple';
    lambdasStruct.lineWidth{iMarket} = 1.5;
    lambdasStruct.lineSpec{iMarket} = ':';
  elseif strcmp(marketCities{iMarket}, 'SAO_PAULO')
    marketIndex{iMarket} = 'IBOVESPA';
    lambdasStruct.lineColor{iMarket} = 'green';
    lambdasStruct.lineWidth{iMarket} = 1.5;
    lambdasStruct.lineSpec{iMarket} = ':';
  end

  % Init struct for performance tracking
  perfResultsStruct.(marketIndex{iMarket}) = struct();

  % Set filenames and paths
  nameFileData = ['Data_', marketIndex{iMarket}];
  pathFileDataClean = [pwd, '/../data_clean/', nameFileData];

  % Read data
  dataTab = readtable([pathFileDataClean, '.csv'], 'PreserveVariableNames', true);
  nStocks = size(dataTab{:, 2:end}, 2);

  % Clean data -----

  % 1) Drop all rows before the cutoff
  dataTab = dataTab(dataTab.Date >= startDate, :);

  % 2) Get stock columns only
  stockVars = setdiff(dataTab.Properties.VariableNames, {'Date'}, 'stable');

  % 3) If there are rows left, evaluate which columns to drop
  X = dataTab{:, stockVars};

  % Drop columns that are all NaN/missing after cutoff
  allMissingMask = all(ismissing(X), 1);

  % Remove those columns
  dataTab(:, stockVars(allMissingMask)) = [];

  % Drop columns whose first remaining value is NaN/missing
  startsMissingMask = ismissing(X(1, :));
  dataTab(:, stockVars(startsMissingMask)) = [];

  % 4) Remove a problematic stocks (with large/late NaN gaps or zero gaps)
  if ismember('VWS', dataTab.Properties.VariableNames)
    removeMask = {'VWS'};
    dataTab(:, removeMask) = [];
  end
  if ismember('MT_PA', dataTab.Properties.VariableNames)
    removeMask = {'MT_PA'};
    dataTab(:, removeMask) = [];
  end
  if ismember('LIFCO_B', dataTab.Properties.VariableNames)
    removeMask = {'LIFCO_B'};
    dataTab(:, removeMask) = [];
  end
  if ismember('ALOS3', dataTab.Properties.VariableNames)
    removeMask = {'ALOS3'};
    dataTab(:, removeMask) = [];
  end
  if ismember('KOFUBL', dataTab.Properties.VariableNames)
    removeMask = {'KOFUBL'};
    dataTab(:, removeMask) = [];
  end
  if ismember('OMAB', dataTab.Properties.VariableNames)
    removeMask = {'OMAB'};
    dataTab(:, removeMask) = [];
  end
  if ismember('GAPB', dataTab.Properties.VariableNames)
    removeMask = {'GAPB'};
    dataTab(:, removeMask) = [];
  end
  if ismember('ROCK_B', dataTab.Properties.VariableNames)
    removeMask = {'ROCK_B'};
    dataTab(:, removeMask) = [];
  end
  if ismember('DEMANT', dataTab.Properties.VariableNames)
    removeMask = {'DEMANT'};
    dataTab(:, removeMask) = [];
  end
  if ismember('NATU3', dataTab.Properties.VariableNames)
    removeMask = {'NATU3'};
    dataTab(:, removeMask) = [];
  end
  if ismember('BMPS', dataTab.Properties.VariableNames)
    removeMask = {'BMPS'};
    dataTab(:, removeMask) = [];
  end

  % 5) Remove dates ouside the considered total time span
  dataTab = dataTab(dataTab.Date >= startDate, :);
  dataTab = dataTab(dataTab.Date <= endDate, :);

  % 6) Interpolate missing entries with filling forward past values
  dataTab = fillmissing(dataTab, 'previous');

  % Get dates and tickers
  dates = datetime(dataTab{:, 1}, 'InputFormat','yyyy-MM-dd');
  tickers = dataTab.Properties.VariableNames(2:end);
  tickersPlot = strrep(tickers, '_', '-'); % Tickers for plots

  % Data dimensionality
  nTradeDays = height(dataTab);
  nAssets = width(dataTab)-1;

  % Compute MP bounds
  aspectRatio = nAssets/windowSize;
  lambdaMaxMp = (1+sqrt(aspectRatio))^2;
  lambdaMinMp = (1-sqrt(aspectRatio))^2;

  % Strip whole price matrix
  dataMat = dataTab{:, 2:end};

  % Number of steps for the rolling window
  nSteps = floor( (nTradeDays-windowSize-2) / stepSize );

  % Compute descriptive stats
  if generateDescrStatsTab == 1

    % Compute log returns for whole matrix
    logReturnsAll = diff(log(dataMat));

    % Compute descriptive stats
    stocksR = nStocks;
    daysR = size(logReturnsAll, 1);
    meanR = mean(logReturnsAll(~isnan(logReturnsAll)));
    stdR  = std(logReturnsAll(~isnan(logReturnsAll)));
    skewR = skewness(logReturnsAll(~isnan(logReturnsAll)));
    kurtR = kurtosis(logReturnsAll(~isnan(logReturnsAll)));
    minR  = min(logReturnsAll(~isnan(logReturnsAll)));
    maxR  = max(logReturnsAll(~isnan(logReturnsAll)));

    % Append a row to the table
    descrStatsTab = [descrStatsTab; {matlab.lang.makeValidName(marketIndex{iMarket}), stocksR, daysR, meanR, stdR, skewR, kurtR, minR, maxR}];

  else

    % Init tab for eigenvalues for a given market
    lambdasStruct.lambdasTab{iMarket} = table([], [], [], [], [], ...
      'VariableNames', {'Date', 'Lambda1', 'Lambda2', 'Lambda3', 'Lambda4'});
    lambdasStruct.lambdasStdTab{iMarket} = table([], [], [], [], [], ...
      'VariableNames', {'Date', 'Lambda1', 'Lambda2', 'Lambda3', 'Lambda4'});

    % Crisis indicator
    isCrisis(1) = 0;
    signalCrisisLambdas = NaN(1, nSteps);

    % Init perf arrays
    linReturnsPortfolio = NaN(nSteps, nMethods);
    cumReturnsPortfolio = NaN(nSteps, nMethods);
    linReturnsPortfolioEw = NaN(nSteps, 1);
    linReturnsSweep = cell(length(gamma1Vals), length(gamma2Vals));
    sampleDates = NaT(1, nSteps);

    % Loop over dates/steps
    for iStep = 1:nSteps

      % Determine current date
      iDate = (iStep-1)*stepSize + windowSize + 2;
      sampleDates(iStep) = dates(iDate);

      pricesToday = dataMat(iDate, :);
      pricesYesterday = dataMat(iDate-1, :);
      logReturnsToday = log(pricesToday) - log(pricesYesterday);
      linReturnsToday = pricesToday ./ pricesYesterday - 1;

      % Determine window
      window = iDate-windowSize : iDate-1;

      % Compute standardized log returns (so that sigma2=1 for MP)
      % Accomodate iDate-1 to capture prices so that Rlog is of size T
      pricesMat = dataMat([iDate-windowSize-1, window], :);

      logReturnsMat = diff(log(pricesMat));
      volLogReturnsVec = std(logReturnsMat).';
      linReturnsMat = pricesMat(2:end,:) ./ pricesMat(1:end-1,:) - 1;

      % Compute correlation matrix (Pearson coefs)
      corrMat = computeCorrMat(logReturnsMat);

      % Compute eigenvalues and eigenvectors
      [eigenVals, eigenVecs] = eigendecompose(corrMat);

      if (generateCumReturnsFig==1) || (generatePerfStatsTab==1) || (generateExposureSweepFig==1)

        % Compute denoised correlation matrix
        corrMatDenoised = denoiseCorrMat(corrMat, lambdaMaxMp);

        % Compute shrunk covariance matrix
        volMat = diag(volLogReturnsVec); % diagonal volatility matrix
        Sigma_clean = shrinkCovMatLw(volMat * corrMatDenoised * volMat, 'constant', shrinkageDensity); % Ledoit-Wolf shrinkage towards Sigma=I

      end

      % Store largest eigenvalues for tracking
      if (generateEigEvoFig==1) || (generateStdEigDynamicsFig==1) || (generateCrossMarketRelationsFig==1)...
          || (generateCrisisDetectionFig==1) || (generateCumReturnsFig==1) || (generatePerfStatsTab==1) || (generateExposureSweepFig==1)

        lambda1 = real(eigenVals(1));
        lambda2 = NaN;
        lambda3 = NaN;
        lambda4 = NaN;
        if length(eigenVals)>=2
          lambda2 = real(eigenVals(2));
          if length(eigenVals)>=3
            lambda3 = real(eigenVals(3));
            if length(eigenVals)>=4
              lambda4 = real(eigenVals(4));
            end
          end
        end
        lambdasStruct.lambdasTab{iMarket} = [lambdasStruct.lambdasTab{iMarket}; {sampleDates(iStep), lambda1, lambda2, lambda3, lambda4}];

      end

      % Crisis detection -----
      if (generateCrisisDetectionFig==1) || (generateCumReturnsFig==1) || (generatePerfStatsTab==1) || (generateExposureSweepFig==1)

        % Eigenvalue-ratio crisis indicator
        eigenvalRatioIndicator = lambdasStruct.lambdasTab{iMarket}{:, 2} ./ lambdasStruct.lambdasTab{iMarket}{:, 3};

        % Remove trend
        trendLambda = movmean(eigenvalRatioIndicator, windowSize, 'omitnan');      % rolling mean trend
        ratioLambdasDetrended = eigenvalRatioIndicator - trendLambda;
        ratioLambdasSmoothened = movmean(ratioLambdasDetrended, nDaysCrisisIndicatorSmoothing, 'omitnan');

        % Crisis signal
        signalCrisisLambdas(iStep) = ratioLambdasSmoothened(end);

        % Label crises
        if (signalCrisisLambdas(iStep) >= thresholdCrisis)
          isCrisis(iStep) = 1;
        else
          isCrisis(iStep) = 0;
        end

      end

      % Portfolio performance  ------
      if (generateCumReturnsFig==1) || (generatePerfStatsTab==1) || (generateExposureSweepFig==1)
        widths = NaN(nMethods,1);
        colors = strings(nMethods,1);
        lines = strings(nMethods,1);
        names = strings(nMethods,1);
        for iMethod = 1:nMethods

          % Call respective functions for the portfolio computation
          switch portfolioMethods{iMethod}
            case 'EQUAL_WEIGHTS'
              weightsVec = 1/nAssets * ones(nAssets, 1);
              colors(iMethod) = 'black';
              lines(iMethod) = '--';
              names(iMethod) = 'Equal-weight';
              widths(iMethod) = 1;
            case 'FIRST_EIGENPORTFOLIO'
              weightsVec = projectOntoLongOnlySimplex(eigenVecs(:, 1)./volLogReturnsVec);
              colors(iMethod) = 'red';
              lines(iMethod) = '-';
              names(iMethod) = '1st eigenportfolio';
              widths(iMethod) = 1;
            case 'MIN_VAR_MARKOWITZ'
              weightsVec = optimizePortfolioMinVarConstrained(Sigma_clean, 10, -1, false);
              colors(iMethod) = 'deepskyblue';
              lines(iMethod) = '-';
              names(iMethod) = 'Min-variance';
              widths(iMethod) = 1;
            case 'MIN_VAR_CONSTRAINED'
              weightsVec = optimizePortfolioMinVarConstrained(Sigma_clean, 0.3, 0.2, isCrisis(iStep));
              colors(iMethod) = 'green';
              lines(iMethod) = '-';
              names(iMethod) = 'Regime-aware';
              widths(iMethod) = 1.5;
          end

          % Collect performance results
          perfResultsStruct.(marketIndex{iMarket}).(portfolioMethods{iMethod}) = struct();
          perfResultsStruct.(marketIndex{iMarket}).(portfolioMethods{iMethod}).color = colors(iMethod);
          perfResultsStruct.(marketIndex{iMarket}).(portfolioMethods{iMethod}).line = lines(iMethod);
          perfResultsStruct.(marketIndex{iMarket}).(portfolioMethods{iMethod}).name = names(iMethod);

          % Compute portfolio returns
          linReturnsPortfolio(iStep, iMethod) = linReturnsToday * weightsVec;
          linReturnsPortfolioEw(iStep) = linReturnsToday/nAssets * ones(nAssets, 1);

        end
      end

      % Sweep exposure thresholds and collect returns
      if generateExposureSweepFig==1
        for i = 1:length(gamma1Vals)
          for j = 1:length(gamma2Vals)
            weightsVecSweep = optimizePortfolioMinVarConstrained(Sigma_clean, gamma1Vals(i), gamma2Vals(j), isCrisis(iStep));
            if ~isempty(weightsVecSweep)
              linReturnsSweep{i, j}(iStep) = linReturnsToday * weightsVecSweep;
            end
          end
        end
      end

    end

    % Standardize eigenvalues
    if (generateStdEigDynamicsFig==1) || (generateCrossMarketRelationsFig==1) || (generateCrisisDetectionFig==1)
      lambdasStruct.lambdasStdTab{iMarket} = lambdasStruct.lambdasTab{iMarket};
      lambdasStruct.lambdasStdTab{iMarket}{:, 2:end} = NaN;  % clear all contents
      for iLambda = 1:length(lambdasStruct.lambdasTab{iMarket}{1, 2:end})
        mu  = mean(lambdasStruct.lambdasTab{iMarket}{:, iLambda+1}, 1, 'omitnan'); % row means
        sig = std(lambdasStruct.lambdasTab{iMarket}{:, iLambda+1}, 1, 'omitnan'); % row std deviations
        lambdasStruct.lambdasStdTab{iMarket}{:, iLambda+1} = (lambdasStruct.lambdasTab{iMarket}{:, iLambda+1} - mu) ./ sig;  % broadcasting: subtract/divide per row
      end
    end

  end

  % Determine crisis periods
  if generateCrisisDetectionFig==1
    dstate = diff(isCrisis); % +1 = rising edge, −1 = falling edge
    riseIdx  = find(dstate ==  1); % indices where 0→1
    fallIdx  = find(dstate == -1); % indices where 1→0
    if max(riseIdx) < length(sampleDates)
      riseTimes = sampleDates(riseIdx + 1);
      fallTimes = sampleDates(fallIdx + 1);
    end
    if isCrisis(1) == 1
      riseTimes = [sampleDates(1), riseTimes];
    end
    if isCrisis(end) == 1
      fallTimes = [fallTimes, sampleDates(end)];
    end
    crisisPeriods = table(riseTimes, fallTimes, ...
      'VariableNames', {'Start','End'});
  end

  % Compute various performance metrics
  if (generatePerfStatsTab==1) || (generateExposureSweepFig==1)
    for iMethod = 1:nMethods
      perfResultsStruct.(marketIndex{iMarket}).(portfolioMethods{iMethod}).linReturns = linReturnsPortfolio(:, iMethod);
      perfStatsTab = table([], [], [], [], [], [], [], 'VariableNames', {'Index', 'Method', 'Mean', 'Vol', 'Sharpe', 'Sortino', 'Treynor'});
      [mn, vol, sharpe, sortino, treynor] = computePerfStats(perfResultsStruct.(marketIndex{iMarket}).(portfolioMethods{iMethod}).linReturns,...
        perfResultsStruct.(marketIndex{iMarket}).EQUAL_WEIGHTS.linReturns);
      perfStatsTab = [perfStatsTab; {matlab.lang.makeValidName(marketIndex{iMarket}), matlab.lang.makeValidName(portfolioMethods{iMethod}), mn, vol, sharpe, sortino, treynor}];
      perfResultsStruct.(marketIndex{iMarket}).(portfolioMethods{iMethod}).perfStatsTab = perfStatsTab;
    end
  end

  % Gather sweep performance results
  if generateExposureSweepFig==1
    sharpeSweep = NaN(length(gamma1Vals), length(gamma2Vals));
    sharpeDelta = NaN(length(gamma1Vals), length(gamma2Vals));
    [~, ~, sharpeMv, ~, ~] = computePerfStats(perfResultsStruct.(marketIndex{iMarket}).MIN_VAR_MARKOWITZ.linReturns, zeros(nSteps, 1));
    for i = 1:length(gamma1Vals)
      for j = 1:length(gamma2Vals)
        [~, ~, sharpeSweep(i, j), ~, ~] = computePerfStats(linReturnsSweep{i,j}, []);

        % Improvement in Sharpe ratio w.r.t. plain Min-Var optimization
        sharpeDelta(i, j) = sharpeSweep(i, j) - sharpeMv;
      end
    end

    % Figure 6. Plot heatmap of Sharpe ratio improvements
    figHandle = figure;
    imagesc(gamma2Vals, gamma1Vals, sharpeDelta);
    set(gca, 'YDir', 'normal');
    colormap(hot)
    colorbar;
    hold on;
    xlabel('Min exposure to second eigenmode');
    ylabel('Max exposure to market eigenmode');
    title([marketIndex{iMarket}, ': Sharpe ratio improvement']);
    [maxVal, linIdx] = max(sharpeDelta(:));
    [rowIdx, colIdx] = ind2sub(size(sharpeDelta), linIdx);

    % Indicate generic exposure thresholds pair: (0.3, 0.2)
    plot(0.2, 0.3, 'ko', 'MarkerSize', 16, 'MarkerFaceColor', rgb('lime'));
    set(gcf, 'Units', 'centimeters', 'Position', [2 2 16 12]);
    set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 12]);
    set(gcf, 'PaperSize', [16 12]);
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 14);
    if resaveFigs==1
      suffixFig = 'Sweep';
      nameFileFig = ['Fig_', marketIndex{iMarket}, '_', suffixCase, '_', suffixFig, '.pdf'];
      print(figHandle, '-dpdf', [pathDirFigs, nameFileFig], '-r300');
      fprintf(['Figure saved to file: ', [pathDirFigs, nameFileFig], '\n']);
    end

  end

  % Figure 5. Plot cumulative returns
  if generateCumReturnsFig==1
    figHandle = figure;
    for iMethod = 1:nMethods
      plot(sampleDates, 100*(cumprod(linReturnsPortfolio(:, iMethod) + 1) - 1), 'Color', rgb(colors(iMethod)), 'Linestyle', lines(iMethod), 'LineWidth', widths(iMethod), 'DisplayName', names(iMethod)); hold on;
    end
    title([marketIndex{iMarket}, ': Cumulative returns']);
    xlabel('Date'); ylabel('Cumulative return, %');
    grid on;
    box off;
    if strcmp(marketCities{iMarket}, 'STOCKHOLM')
      legend('Location', 'NorthWest');
    end

    set(gcf, 'Units', 'centimeters', 'Position', [2 2 16 12]);
    set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 12]);
    set(gcf, 'PaperSize', [16 12]);
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 14);
    if resaveFigs==1
      suffixFig = 'Returns';
      nameFileFig = ['Fig_', marketIndex{iMarket}, '_', suffixCase, '_', suffixFig, '.pdf'];
      print(figHandle, '-dpdf', [pathDirFigs, nameFileFig], '-r300');
      fprintf(['Figure saved to file: ', [pathDirFigs, nameFileFig], '\n']);
    end
  end

  % Perform OLS regression on eigenportfolios
  if generateOlsEigenbetasTab == 1
    nLambdasOlsRegEigenbetas = 3;
    olsRegEigenbetasRows = buildEigenbetaTable(olsRegEigenbetasRows, marketIndex{iMarket}, logReturnsMat, nLambdasOlsRegEigenbetas);
  end

  if generateEigEvoFig == 1

    % Figure 1. Plot eigenvalue dynamics
    figHandle = figure;
    plot(lambdasStruct.lambdasTab{iMarket}.Date, lambdasStruct.lambdasTab{iMarket}.Lambda1, 'Color', rgb('Red'), 'LineWidth', 1.5 ,'DisplayName','1st eigenvalue'); hold on;
    plot(lambdasStruct.lambdasTab{iMarket}.Date, lambdasStruct.lambdasTab{iMarket}.Lambda2, 'Color', rgb('Blue'), 'LineWidth', 1, 'DisplayName','2nd eigenvalue');
    plot(lambdasStruct.lambdasTab{iMarket}.Date, lambdasStruct.lambdasTab{iMarket}.Lambda3, 'Color', rgb('Orange'), 'LineWidth', 1, 'DisplayName','3rd eigenvalue');
    plot(lambdasStruct.lambdasTab{iMarket}.Date, lambdasStruct.lambdasTab{iMarket}.Lambda4, 'Color', rgb('Deepskyblue'), 'LineWidth', 1, 'DisplayName','4th eigenvalue');
    yline(lambdaMaxMp, 'k--', 'LineWidth', 2, 'DisplayName','MP upper bound');
    xlabel('Date'); ylabel('Eigenvalue');
    title([marketIndex{iMarket}, ': Eigenvalues']);
    if strcmp(marketCities{iMarket}, 'STOCKHOLM')
      lg = legend('Location', 'West');
      lg.Units = 'normalized';
      lg.Position = [0.22 0.33 0.15 0.1]; % [x y width height]
    end
    grid on;
    box off;
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 14);
    set(gcf, 'Units', 'centimeters', 'Position', [2 2 16 12]);
    set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 12]);
    set(gcf, 'PaperSize', [16 12]);
    if resaveFigs==1
      suffixFig = 'Eig';
      nameFileFig = ['Fig_', marketIndex{iMarket}, '_', suffixCase, '_', suffixFig, '.pdf'];
      print(figHandle, '-dpdf', [pathDirFigs, nameFileFig], '-r300');
      fprintf(['Figure saved to file: ', [pathDirFigs, nameFileFig], '\n']);
    end
  end

  % Figure 2. Plot standardized eigenvalue dynamics
  if generateStdEigDynamicsFig==1
    figHandle = figure;

    plot(lambdasStruct.lambdasStdTab{iMarket}.Date, lambdasStruct.lambdasStdTab{iMarket}.Lambda1, 'Color', rgb('Red'), 'LineWidth', 1.5, 'DisplayName','1st eigenvalue'); hold on;
    plot(lambdasStruct.lambdasStdTab{iMarket}.Date, lambdasStruct.lambdasStdTab{iMarket}.Lambda2, 'Color', rgb('Blue'), 'LineWidth', 1, 'DisplayName','2nd eigenvalue');
    xlabel('Date'); ylabel('Eigenvalue');
    title([marketIndex{iMarket}, ': Standardized eigenvalues']);
    if strcmp(marketCities{iMarket}, 'STOCKHOLM')
      legend('Location','North');
    end
    grid on;
    box off;
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 14);
    set(gcf, 'Units', 'centimeters', 'Position', [2 2 16 12]);
    set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 12]);
    set(gcf, 'PaperSize', [16 12]);
    if resaveFigs==1
      suffixFig = 'StdEig';
      nameFileFig = ['Fig_', marketIndex{iMarket}, '_', suffixCase, '_', suffixFig, '.pdf'];
      print(figHandle, '-dpdf', [pathDirFigs, nameFileFig], '-r300');
      fprintf(['Figure saved to file: ', [pathDirFigs, nameFileFig], '\n']);
    end
  end

end

% Retime series for correlation computation across markets
if generateCrossMarketRelationsFig==1
  lambdasStdRetimedCell = cell(1, nMarkets);
  for iMarket = 1:length(marketCities)
    lambdasStdRetimedCell{iMarket} = timetable(lambdasStruct.lambdasTab{iMarket}.Date, lambdasStruct.lambdasTab{iMarket}.Lambda1, 'VariableNames', {matlab.lang.makeValidName(marketIndex{iMarket})});
    lambdasStdRetimedCell{iMarket} = retime(lambdasStdRetimedCell{iMarket}, 'weekly', 'mean');
  end
  lambdasStdSyncedCell = synchronize(lambdasStdRetimedCell{:}, 'union', 'mean');

  crossCorrMat = NaN(nMarkets-1, nMarkets-1);
  for iMarket = 1:length(marketCities)
    for jMarket = 1:length(marketCities)
      crossCorrMat(iMarket, jMarket) = corr(lambdasStdSyncedCell.(marketIndex{iMarket}), lambdasStdSyncedCell.(marketIndex{jMarket}), 'Type', 'Spearman', 'Rows', 'complete');
    end
  end
  labels = marketIndex;
end

% Table 1. Save descriptive stats table
if generateDescrStatsTab==1
  disp(descrStatsTab);
  if resaveTabs==1
    suffixTab = 'DescrStats';
    nameFileTab = ['Tab_', suffixCase, '_', suffixTab, '.tex'];
    saveDescriptiveStatsTab(descrStatsTab, [pathDirTabs, nameFileTab]);
  end
end

% Table 2. Save OLS regressions table
if generateOlsEigenbetasTab==1
  olsRegEigenbetasTab = [olsRegEigenbetasTab; olsRegEigenbetasRows];
  disp(olsRegEigenbetasTab);
  if resaveTabs==1
    suffixTab = 'Eigenbetas';
    nameFileTab = ['Tab_', suffixCase, '_', suffixTab, '.tex'];
    saveEigenbetasTab(olsRegEigenbetasTab, [pathDirTabs, nameFileTab]);
  end
end

% Table 3. Save performance summary table
if generatePerfStatsTab==1
  summaryTab = buildPerfSummaryTab(perfResultsStruct);
  disp(summaryTab);
  if resaveTabs==1
    suffixTab = 'PerfSummary';
    nameFileTab = ['Tab_', suffixCase, '_', suffixTab, '.tex'];
    savePerfSummaryTab(summaryTab, [pathDirTabs, nameFileTab]);
  end
end

% Figure 3. Cross-market relations
if generateCrossMarketRelationsFig==1

  % (a) Plot standardized first eigenmodes for various markets
  figHandle = figure;
  for iMarket = 1:length(marketCities)
    plot(lambdasStruct.lambdasStdTab{iMarket}.Date, lambdasStruct.lambdasStdTab{iMarket}.Lambda1, 'color', rgb(lambdasStruct.lineColor{iMarket}), 'LineWidth',...
      lambdasStruct.lineWidth{iMarket}, 'linestyle', lambdasStruct.lineSpec{iMarket}, 'DisplayName', marketIndex{iMarket}); hold on;
  end
  xlabel('Date'); ylabel('Largest standardized eigenvalue');
  ylim([-4, 3.5])
  title('Largest standardized eigenvalues');
  legend('Location', 'South', 'NumColumns', 3);
  grid on;
  box off;
  set(findall(gcf, '-property', 'FontSize'), 'FontSize', 14);
  set(gcf, 'Units', 'centimeters', 'Position', [2 2 16 12]);
  set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 12]);
  set(gcf, 'PaperSize', [16 12]);
  if resaveFigs==1
    suffixFig = 'StdEigSynchro';
    nameFileFig = ['Fig_', suffixCase, '_', suffixFig, '.pdf'];
    print(figHandle, '-dpdf', [pathDirFigs, nameFileFig], '-r300');
    fprintf(['Figure saved to file: ', [pathDirFigs, nameFileFig], '\n']);
  end

  % (b) Plot heatmap of correlations of market eigenmodes
  figHandle = figure;
  h = heatmap(labels, labels, crossCorrMat, ...
    'Colormap', hot, ...
    'ColorLimits', [0 1]); % keep scale symmetric
  h.CellLabelFormat = '%.2f'; % show 2 decimals inside cells
  title('Pairwise correlation of largest stadardized eigenvalues');
  colorbar;
  set(findall(gcf, '-property', 'FontSize'), 'FontSize', 13);
  set(gcf, 'Units', 'centimeters', 'Position', [2 2 16 12]);
  set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 12]);
  set(gcf, 'PaperSize', [16 12]);
  if resaveFigs==1
    suffixFig = 'StdEigCorr';
    nameFileFig = ['Fig_', suffixCase, '_', suffixFig, '.pdf'];
    print(figHandle, '-dpdf', [pathDirFigs, 'Fig_', nameFileFig], '-r300');
    fprintf(['Figure saved to file: ', [pathDirFigs, nameFileFig], '\n']);
  end

  % (c) Plot standardized second eigenmodes for various markets
  figHandle = figure;
  for iMarket = 1:length(marketCities)
    plot(lambdasStruct.lambdasStdTab{iMarket}.Date, lambdasStruct.lambdasStdTab{iMarket}.Lambda2, 'color', rgb(lambdasStruct.lineColor{iMarket}), 'LineWidth',...
      lambdasStruct.lineWidth{iMarket}, 'linestyle', lambdasStruct.lineSpec{iMarket}, 'DisplayName', marketIndex{iMarket}); hold on;
  end
  xlabel('Date'); ylabel('Second standardized eigenvalue');
  ylim([-4, 3.5])
  title('Second standardized eigenvalues');
  legend('Location', 'South', 'NumColumns', 3);
  grid on;
  box off;
  set(findall(gcf, '-property', 'FontSize'), 'FontSize', 14);
  set(gcf, 'Units', 'centimeters', 'Position', [2 2 16 12]);
  set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 12]);
  set(gcf, 'PaperSize', [16 12]);
  if resaveFigs==1
    suffixFig = 'StdEig2Synchro';
    nameFileFig = ['Fig_', suffixCase, '_', suffixFig, '.pdf'];
    print(figHandle, '-dpdf', [pathDirFigs, nameFileFig], '-r300');
    fprintf(['Figure saved to file: ', [pathDirFigs, nameFileFig], '\n']);
  end

end

% Figure 4. Plot crisis indicator and crisis periods
if generateCrisisDetectionFig==1
  figHandle = figure;
  hold on;
  set(findall(gcf, '-property', 'FontSize'), 'FontSize', 10);

  plot(sampleDates, signalCrisisLambdas, 'color', rgb('purple'), 'LineWidth', 1.5 ,'DisplayName', 'Crisis indicator'); hold on;
  plot(lambdasStruct.lambdasStdTab{iMarket}.Date, lambdasStruct.lambdasStdTab{iMarket}.Lambda1, 'Color', rgb('red'), 'LineWidth', 1, 'DisplayName', '1st eigenvalue'); hold on;
  plot(lambdasStruct.lambdasStdTab{iMarket}.Date, lambdasStruct.lambdasStdTab{iMarket}.Lambda2, 'Color', rgb('blue'), 'LineWidth', 1, 'DisplayName', '2nd eigenvalue'); hold on;

  yline(0, 'LineWidth', 1, 'DisplayName', 'Threshold');
  title([marketIndex{iMarket}, ': Crises']);
  yl = ylim;
  for i = 1:length(crisisPeriods.Start)
    fill([crisisPeriods.Start(i) crisisPeriods.End(i) ...
      crisisPeriods.End(i) crisisPeriods.Start(i)], ...
      [yl(1) yl(1) yl(2) yl(2)], ...
      rgb('gold'), 'FaceAlpha', 0.5, 'EdgeColor','none', 'HandleVisibility','off');
  end
  hCrisis = fill([0 0 0 0],[0 0 0 0], rgb('gold'), ...
    'FaceAlpha',0.2, 'EdgeColor','none', 'DisplayName','Crisis period');
  ax = gca;
  ax.Children = [ax.Children(end); ax.Children(1:end-1)]; % move first child to bottom
  grid on
  box off;
  xlabel('Date'); ylabel('Crisis indicator');
  legend('Location', 'SouthEast');

  set(gcf, 'Units', 'centimeters', 'Position', [2 2 40 12]);
  set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 40 12]);
  set(gcf, 'PaperSize', [40 12]);
  if resaveFigs==1
    suffixFig = 'Crisis';
    nameFileFig = ['Fig_', suffixCase, '_', suffixFig, '.pdf'];
    print(figHandle, '-dpdf', [pathDirFigs, nameFileFig], '-r300');
    fprintf(['Figure saved to file: ', [pathDirFigs, nameFileFig], '\n']);
  end

end
