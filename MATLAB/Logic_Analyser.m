%% STM32 Logic Analyzer Interface
% Description: Reads 2-channel binary data from STM32 via UART

clear; clc; close all;

%% Configuration
SERIAL_PORT = 'COM6'; % Check device manager if this changes
BAUD_RATE   = 115200;
WINDOW_SEC  = 3.0;    % How many seconds of data to show on screen

% Print available ports just in case
disp('Found Ports:');
disp(serialportlist("available"));

%% Setup Connection
try
    stm32 = serialport(SERIAL_PORT, BAUD_RATE);
    configureTerminator(stm32, "CR/LF"); % Good practice if sending lines
    flush(stm32); % Clear any old junk data
    disp(['Connected to ' SERIAL_PORT]);
catch ME
    error(['Failed to open port. Is it busy? ' ME.message]);
end

%% Plot Setup
hFig = figure('Name', 'STM32 Logic Analyzer', 'Color', 'w');

% Channel 1 Setup
subplot(2, 1, 1);
hLine1 = plot(nan, nan, 'b', 'LineWidth', 1.5);
title('Channel 1 (PC0)');
ylim([-0.2 1.2]); % Give it some breathing room
yticks([0 1]);
ylabel('Logic Level');
grid on;

% Channel 2 Setup
subplot(2, 1, 2);
hLine2 = plot(nan, nan, 'r', 'LineWidth', 1.5);
title('Channel 2 (PC1)');
ylim([-0.2 1.2]);
yticks([0 1]);
xlabel('Time (s)');
ylabel('Logic Level');
grid on;

%% Data Loop
raw_pc0 = [];
raw_pc1 = [];
t_log   = [];

startTime = datetime('now');

disp('Capturing data... (Press Ctrl+C to stop)');

while ishandle(hFig) % Runs until you close the figure window
    
    if stm32.NumBytesAvailable >= 2
        % Read 2 bytes directly
        data = read(stm32, stm32.NumBytesAvailable, "uint8");
        charData = char(data');
        
        % Simple parsing - assumes stream is "1010..." or similar
        % Iterate through received chunk in case we got a burst of data
        for i = 1:2:length(charData)-1
            val1 = charData(i);
            val2 = charData(i+1);
            
            % Update arrays
            t_now = seconds(datetime('now') - startTime);
            t_log(end+1)   = t_now;
            raw_pc0(end+1) = str2double(val1);
            raw_pc1(end+1) = str2double(val2);
        end
        
        % --- Update Plot (Scrolling) ---
        % Only keep data within the view window to keep it fast
        if t_now > WINDOW_SEC
            t_start = t_now - WINDOW_SEC;
            % Filter indices logic
            idx = t_log > t_start;
            
            % Update graph data
            set(hLine1, 'XData', t_log(idx), 'YData', raw_pc0(idx));
            set(hLine2, 'XData', t_log(idx), 'YData', raw_pc1(idx));
            
            % Scroll X-Axis
            subplot(2,1,1); xlim([t_start, t_now]);
            subplot(2,1,2); xlim([t_start, t_now]);
        else
            % Static view for first few seconds
            set(hLine1, 'XData', t_log, 'YData', raw_pc0);
            set(hLine2, 'XData', t_log, 'YData', raw_pc1);
            
            subplot(2,1,1); xlim([0, WINDOW_SEC]);
            subplot(2,1,2); xlim([0, WINDOW_SEC]);
        end
        
        drawnow limitrate; % smoother updates than pause()
    end
end

clear stm32;
disp('Connection Closed.');
