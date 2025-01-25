% Check available serial ports
availablePorts = serialportlist("available");
disp('Available COM Ports:');
disp(availablePorts);

% Specify the COM port to test, change port and buad rate according to yours
serialPort = 'COM6';
baudRate = 115200;

% Create a serial port object
s = serialport(serialPort, baudRate);

% Initialize data storage
pc0Data = [];
pc1Data = []; 
timeData = []; 

% Create a figure for plotting
figure('Position', [100, 100, 600, 400]);
hold on;

% Create axes for plotting
ax1 = subplot(2, 1, 1);
title('Channel 1 (PC0)');
ylim([-0.1 1.1]);
xlabel('Time (s)');
ylabel('State');
hold(ax1, 'on');

ax2 = subplot(2, 1, 2);
title('Channel 2 (PC1)');
ylim([-0.1 1.1]);
xlabel('Time (s)');
ylabel('State');
hold(ax2, 'on');

% Set the initial time
startTime = datetime('now');

% Main loop to read data
try
    disp('Starting to read data from the serial port...');
    while true
        % Check if there are bytes available to read
        if s.NumBytesAvailable > 0
            % Read available bytes
            data = read(s, s.NumBytesAvailable, "uint8");
            
            % Convert the data to characters
            dataStr = char(data');
            
            % Display the received data for test purposes
            fprintf('Received: %s\n', dataStr);
            
            % Ensure we have enough data (2 characters)
            if length(dataStr) >= 2
                % Get the first character for PC0 and second character for PC1
                pc0Char = dataStr(1); 
                pc1Char = dataStr(2);
                
                % Convert characters to binary values (1 or 0)
                pc0 = (pc0Char == '1');
                pc1 = (pc1Char == '1');

                % Store the data, time in seconds
                currentTime = seconds(datetime('now') - startTime);
                
                % Append the new data to the arrays
                timeData(end + 1) = currentTime; 
                pc0Data(end + 1) = pc0; % Store as binary value (0 or 1)
                pc1Data(end + 1) = pc1; % Store as binary value (0 or 1)

                % Print the gathered data
                fprintf('Time: %.2f s, PC0: %d, PC1: %d\n', currentTime, pc0, pc1);

                % Clear previous plots
                cla(ax1);
                cla(ax2);
                
                % Plot the data
                if currentTime <= 3
                    % For the first 3 seconds, plot all data from the start
                    plot(ax1, timeData, pc0Data, 'b'); 
                    plot(ax2, timeData, pc1Data, 'r');
                    % Set the x-axis to show the full range up to `currentTime`
                    xlim(ax1, [0 3]);
                    xlim(ax2, [0 3]);
                else
                    % After 3 seconds, plot only the last 3 seconds of data
                    validIndices = timeData >= (currentTime - 3);
                    plot(ax1, timeData(validIndices) - (currentTime - 3), pc0Data(validIndices), 'b'); % Plot PC0
                    plot(ax2, timeData(validIndices) - (currentTime - 3), pc1Data(validIndices), 'r'); % Plot PC1
                    % The x-axis fixed to [0 3]
                    xlim(ax1, [0 3]);
                    xlim(ax2, [0 3]);
                end
                
                % Delay briefly to allow updates on plat
                pause(0.01);
            else
                fprintf('Received data is less than 2 characters: %s\n', dataStr);
            end
        end
    end
catch ME
    disp('Error occurred:');
    disp(ME.message);
end

% Automatically closes the serial port when done
clear s; 