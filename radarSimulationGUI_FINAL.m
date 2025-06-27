function radarSimulationGUI_FINAL()
    % Create main figure
    fig = figure('Name', 'Advanced Radar Defense System', 'NumberTitle', 'off', ...
                 'Position', [100 100 1300 750], 'Color', [0.1 0.1 0.1], ...
                 'CloseRequestFcn', @onCloseRequest);

    global paused resetRequested abortRequested trailsVisible logsVisible
paused = false;
resetRequested = false;
abortRequested = false;
trailsVisible = true;
logsVisible = true;


global  logsFig;
logsVisible = false;
logsFig = [];

global app missile_launched missile_pos;
missile_launched = false;
missile_pos = [0, 0];  % Initial dummy position


    % Initialize app structure
    app = struct();
    app.targetHistory = [];
    app.missileHistory = [];
    app.heightHistory = [];
    app.running = false;
    app.scanNumber = 0;
    app.missileSpeed = 1.0;
    app.soundVolume = 0.5;
    app.zoomLevel = 60;

    % Load sound files
    try
        [app.sirenSound, app.sirenFs] = audioread('siren.mp3');
        [app.buzzerSound, app.buzzerFs] = audioread('buzzer.mp3');
    catch
        warning('Sound files not found. Sound effects will be disabled.');
        app.sirenSound = [];
        app.buzzerSound = [];
    end


% Left-side Vertical Control Panel
sidePanel = uipanel('Parent', fig, 'Title', 'SYSTEM CONTROL', ...
                   'Position', [0.01 0.01 0.13 0.98], ...
                   'BackgroundColor', [0.1 0.1 0.1], ...
                   'ForegroundColor', 'w', 'FontWeight', 'bold');

% ========== Buttons and LED Display ==========

% === TARGET & MISSILE COLOR REPRESENTATION (TOP of Left Panel) ===

% Target (Red Dot)
uicontrol('Parent', sidePanel, 'Style', 'text', ...
          'String', '● Target', ...
          'Units', 'normalized', 'Position', [0.1 0.96 0.8 0.03], ...
          'FontSize', 11, 'ForegroundColor', 'red', ...
          'BackgroundColor', [0.78, 0.88, 0.95], 'FontWeight', 'bold');

% Missile (Blue Dot)
uicontrol('Parent', sidePanel, 'Style', 'text', ...
          'String', '● Missile', ...
          'Units', 'normalized', 'Position', [0.1 0.93 0.8 0.03], ...
          'FontSize', 11, 'ForegroundColor', 'blue', ...
          'BackgroundColor', [0.78, 0.88, 0.95], 'FontWeight', 'bold');


   % Snapshot Button
     app.snapshotButton = uicontrol('Parent', sidePanel, 'Style', 'pushbutton', ...
    'String', '📷 Snapshot', 'Units', 'normalized', ...
    'Position', [0.1 0.84 0.8 0.07], ...
    'Callback', @takeSnapshot, 'FontSize', 10, ...
    'BackgroundColor', [0.93, 0.75, 0.10], ...  % Mustard  Yellow
    'ForegroundColor', 'k');                % Black text for contrast


% Save Button
app.saveButton = uicontrol('Parent', sidePanel, 'Style', 'pushbutton', ...
    'String', 'Save Data', 'Units', 'normalized', ...
    'Position', [0.1 0.75 0.8 0.07], ...
    'Callback', @saveData, 'FontSize', 10, ...
    'BackgroundColor', [0.3 0.3 0.3], 'ForegroundColor', 'w');

% Date/Time Display
app.timeText = uicontrol('Parent', sidePanel, 'Style', 'text', ...
    'String', datestr(now,'HH:MM:SS'), 'Units', 'normalized', ...
    'Position', [0.1 0.66 0.8 0.06], 'FontSize', 14, ...
    'ForegroundColor', 'c', 'BackgroundColor', [0.1 0.1 0.1]);

% LED Section Title
uicontrol('Parent', sidePanel, 'Style', 'text', 'String', 'STATUS INDICATORS', ...
    'Units', 'normalized', 'Position', [0.1 0.61 0.8 0.04], ...
    'FontSize', 8, 'ForegroundColor', 'w', 'BackgroundColor', [0.1 0.1 0.1]);

% LED Indicators
app.powerLED = uicontrol('Parent', sidePanel, 'Style', 'text', ...
    'String', '● Power', 'Units', 'normalized', ...
    'Position', [0.1 0.56 0.8 0.04], 'FontSize', 11, ...
    'ForegroundColor', 'green', 'BackgroundColor', [0.1 0.1 0.1]);

app.readyLED = uicontrol('Parent', sidePanel, 'Style', 'text', ...
    'String', '● Missile Ready', 'Units', 'normalized', ...
    'Position', [0.1 0.51 0.8 0.04], 'FontSize', 11, ...
    'ForegroundColor', 'yellow', 'BackgroundColor', [0.1 0.1 0.1]);

app.alertLED = uicontrol('Parent', sidePanel, 'Style', 'text', ...
    'String', '● Alert', 'Units', 'normalized', ...
    'Position', [0.1 0.46 0.8 0.04], 'FontSize', 11, ...
    'ForegroundColor', 'red', 'BackgroundColor', [0.1 0.1 0.1]);

% Emergency Abort
app.abortButton = uicontrol('Parent', sidePanel, 'Style', 'pushbutton', ...
    'String', 'EMERGENCY ABORT', 'Units', 'normalized', ...
    'Position', [0.1 0.37 0.8 0.07], 'FontSize', 10, ...
    'Callback', @abortEmergency, ...
    'BackgroundColor', [0.8 0.1 0.1], 'ForegroundColor', 'w');

% Pause/Resume Button
app.pauseButton = uicontrol('Parent', sidePanel, 'Style', 'pushbutton', ...
    'String', 'Pause/Resume', 'Units', 'normalized', ...
    'Position', [0.1 0.28 0.8 0.07], 'FontSize', 10, ...
    'Callback', @pauseRadar, ...
    'BackgroundColor', [0.6 0.4 0.2], 'ForegroundColor', 'w');

% Reset Button
app.resetButton = uicontrol('Parent', sidePanel, 'Style', 'pushbutton', ...
    'String', 'Reset', 'Units', 'normalized', ...
    'Position', [0.1 0.19 0.8 0.07], 'FontSize', 10, ...
    'Callback', @resetRadar, ...
    'BackgroundColor', [0.3 0.3 0.3], 'ForegroundColor', 'w');

% Show/Hide Radar Trails
app.trailsButton = uicontrol('Parent', sidePanel, 'Style', 'togglebutton', ...
    'String', 'Show/Hide Trails', 'Units', 'normalized', ...
    'Position', [0.1 0.10 0.8 0.07], 'FontSize', 9, ...
    'Callback', @toggleTrails, ...
    'BackgroundColor', [0.2 0.6 0.6], 'ForegroundColor', 'w');

% Show/Hide Logs
app.logsButton = uicontrol('Parent', sidePanel, 'Style', 'togglebutton', ...
    'String', 'Show/Hide Logs', 'Units', 'normalized', ...
    'Position', [0.1 0.01 0.8 0.07], 'FontSize', 9, ...
    'Callback', @toggleLogs, ...
    'BackgroundColor', [0.2 0.4 0.7], 'ForegroundColor', 'w');

% Update Time Continuously
timerObj = timer('ExecutionMode', 'fixedSpacing', 'Period', 1, ...
    'TimerFcn', @(~,~) set(app.timeText, 'String', datestr(now,'HH:MM:SS')));
start(timerObj);


    % ======================
    % RADAR DISPLAY (30% width, top-left)
    % ======================
    radarPanel = uipanel('Parent', fig, 'Title', 'RADAR DISPLAY', ...
                        'Position', [0.16 0.34 0.52 0.65], ...
                        'BackgroundColor', [0.1 0.1 0.1], ...
                        'ForegroundColor', 'w', 'FontWeight', 'bold');
    
    app.pax = polaraxes('Parent', radarPanel, 'Position', [0.1 0.1 0.8 0.8], 'Color', 'k');
    hold(app.pax, 'on');
    app.pax.RLim = [0 app.zoomLevel];
    app.pax.ThetaDir = 'clockwise';
    app.pax.Color = [0.2 0.2 0.2];
    title(app.pax, 'Radar Scan', 'Color', 'w', 'FontSize', 12);
    app.sweep_line = animatedline(app.pax, 'Color', 'g', 'LineWidth', 2);

    % Radar Graphics
    app.sweep_line = animatedline('Color', [0.2 0.8 0.2], 'LineWidth', 3, 'Parent', app.pax);
    app.target_path = animatedline('Color', 'r', 'LineStyle', '-', 'Marker', '.', 'Parent', app.pax);
    app.missile_path = animatedline('Color', 'b', 'LineStyle', '--', 'Marker', 'o', 'Parent', app.pax);
    app.target_dot = plot(app.pax, NaN, NaN, 'r.', 'MarkerSize', 18);
    app.missile_dot = plot(app.pax, NaN, NaN, 'bo', 'MarkerSize', 12, 'LineWidth', 2);
    app.explosion_effect = plot(app.pax, NaN, NaN, 'y*', 'MarkerSize', 40, 'Visible', 'off');

    % ======================
    % CONTROL BUTTONS (between radar and sliders)
    % ======================
    btnPanel = uipanel('Parent', fig, 'Position', [0.16 0.24 0.52 0.08], ...
                      'BackgroundColor', [0.15 0.15 0.15]);
    
    app.sweepButton = uicontrol('Parent', btnPanel, 'Style', 'pushbutton', ...
                               'String', 'START', 'Units', 'normalized', ...
                               'Position', [0.1 0.2 0.35 0.6], ...
                               'Callback', @startSweep, 'BackgroundColor', [0 0.5 0], ...
                               'ForegroundColor', 'w', 'FontWeight', 'bold', 'FontSize', 10);
    
    app.stopButton = uicontrol('Parent', btnPanel, 'Style', 'pushbutton', ...
                             'String', 'STOP', 'Units', 'normalized', ...
                             'Position', [0.55 0.2 0.35 0.6], ...
                             'Callback', @stopSweep, 'BackgroundColor', [0.6 0 0], ...
                             'ForegroundColor', 'w', 'FontWeight', 'bold', 'FontSize', 10);


   
% ======================
    % SLIDERS (left bottom, horizontal layout)
    % ======================
    sliderPanel = uipanel('Parent', fig, 'Title', 'CONTROLS', ...
                         'Position', [0.16 0.01 0.52 0.2], ...
                         'BackgroundColor', [0.15 0.15 0.15], ...
                         'ForegroundColor', 'w', 'FontWeight', 'bold');

    % STATUS text - centered at top
app.statusText = uicontrol('Parent', sliderPanel, 'Style', 'text', ...
                         'String', 'STATUS: STANDBY', 'Units', 'normalized', ...
                         'Position', [0.35 0.47 0.3 0.4], ...  % Centered horizontally
                         'FontSize', 10, 'ForegroundColor', 'r', ...
                         'BackgroundColor', [0.15 0.15 0.15], 'FontWeight', 'bold');

% Updated vertical level for all sliders and labels
sliderY = 0.2;
labelY = 0.47;
sliderWidth = 0.27;
sliderHeight = 0.16;

% Radar Range Slider (Left)
uicontrol('Parent', sliderPanel, 'Style', 'text', 'String', 'Radar Range', ...
         'Units', 'normalized', 'Position', [0.05 labelY sliderWidth 0.1], ...
         'FontSize', 9, 'ForegroundColor', 'w', 'BackgroundColor', [0.15 0.15 0.15]);
app.zoomSlider = uicontrol('Parent', sliderPanel, 'Style', 'slider', ...
                          'Min', 20, 'Max', 60, 'Value', 60, 'Units', 'normalized', ...
                          'Position', [0.05 sliderY sliderWidth sliderHeight], ...
                          'Callback', @updateZoom);

% Missile Speed Slider (Center)
uicontrol('Parent', sliderPanel, 'Style', 'text', 'String', 'Missile Speed', ...
         'Units', 'normalized', 'Position', [0.375 labelY sliderWidth 0.1], ...
         'FontSize', 9, 'ForegroundColor', 'w', 'BackgroundColor', [0.15 0.15 0.15]);
app.missileSpeedSlider = uicontrol('Parent', sliderPanel, 'Style', 'slider', ...
                                  'Min', 1, 'Max', 4, 'Value', 1, 'Units', 'normalized', ...
                                  'Position', [0.375 sliderY sliderWidth sliderHeight], ...
                                  'Callback', @updateMissileSpeed);

% Sound Volume Slider (Right)
uicontrol('Parent', sliderPanel, 'Style', 'text', 'String', 'Sound Volume', ...
         'Units', 'normalized', 'Position', [0.7 labelY sliderWidth 0.1], ...
         'FontSize', 9, 'ForegroundColor', 'w', 'BackgroundColor', [0.15 0.15 0.15]);
app.soundSlider = uicontrol('Parent', sliderPanel, 'Style', 'slider', ...
                           'Min', 0, 'Max', 1, 'Value', 0.5, 'Units', 'normalized', ...
                           'Position', [0.7 sliderY sliderWidth sliderHeight], ...
                           'Callback', @updateSoundVolume);
    

    % ======================
    % DATA TABLES (right side, vertical stack)
    % ======================
    tablePanel = uipanel('Parent', fig, 'Title', 'TRACKING DATA', ...
                        'Position', [0.7 0.01 0.63 0.98], ...
                        'BackgroundColor', [0.15 0.15 0.15], ...
                        'ForegroundColor', 'w', 'FontWeight', 'bold');
    
    % Calculate table heights (30% each with 2% spacing)
    tableHeight = 0.30;
    spacing = 0.02;
    tableTopY = 0.97; 
   
    % Target Tracking Table (top)
    uicontrol('Parent', tablePanel, 'Style', 'text', 'String', 'TARGET TRACKING DATA', ...
             'Units', 'normalized', 'Position', [0.03 tableTopY-0.08 0.4 0.05], ...
             'FontSize', 10, 'ForegroundColor', 'r', 'BackgroundColor', [0.15 0.15 0.15], ...
             'FontWeight', 'bold');
    app.targetTable = uitable('Parent', tablePanel, 'Units', 'normalized', ...
                            'Position', [0.05 tableTopY-tableHeight 0.36 tableHeight-0.07], ...
                            'ColumnName', {'Scan', 'Range(km)', 'Az(°)', 'H(km)'}, ...
                            'ColumnFormat', {'numeric', 'numeric', 'numeric', 'numeric'}, ...
                            'ColumnWidth', {30, 75, 80, 70}, 'FontSize', 9, ...
                            'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w');

   % Missile Tracking Table (middle)
    uicontrol('Parent', tablePanel, 'Style', 'text', 'String', 'MISSILE TRACKING DATA', ...
             'Units', 'normalized', 'Position', [0.05 0.55 0.3 0.05], ...
             'FontSize', 10, 'ForegroundColor', 'b', 'BackgroundColor', [0.15 0.15 0.15], ...
             'FontWeight', 'bold');
    app.missileTable = uitable('Parent', tablePanel, 'Units', 'normalized', ...
                             'Position', [0.05 0.64-tableHeight 0.36 tableHeight-0.07], ...
                             'ColumnName', {'Scan', 'Range(km)', 'Az(°)', 'H(km)'}, ...
                             'ColumnFormat', {'numeric', 'numeric', 'numeric', 'numeric'}, ...
                             'ColumnWidth', {40, 75, 80, 70}, 'FontSize', 9, ...
                             'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w');
   
    % Height Comparison Table (bottom)
    uicontrol('Parent', tablePanel, 'Style', 'text', 'String', 'HEIGHT COMPARISON DATA', ...
             'Units', 'normalized', 'Position', [0.05 0.23 0.3 0.05], ...
             'FontSize', 10, 'ForegroundColor', 'm', 'BackgroundColor', [0.15 0.15 0.15], ...
             'FontWeight', 'bold');
    app.heightTable = uitable('Parent', tablePanel, 'Units', 'normalized', ...
                            'Position', [0.05 0.01 0.36 tableHeight-0.07], ...
                            'ColumnName', {'Scan', 'TgtH(km)', 'MisH(km)', 'ΔH(km)'}, ...
                            'ColumnFormat', {'numeric', 'numeric', 'numeric', 'numeric'}, ...
                            'ColumnWidth', {40, 75, 80, 70}, 'FontSize', 9, ...
                            'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w');

% ======================
    % CALLBACK FUNCTIONS
    % ======================

 function startSweep(~,~)
        app.running = true;
        set(app.sweepButton, 'Enable', 'off');
        set(app.stopButton, 'Enable', 'on');
        set(app.statusText, 'String', 'STATUS: ACTIVE', 'ForegroundColor', 'g');
        app.scanNumber = 0;

        % Initialize tracking variables
        theta = 0; 
        t = 0; 
        missile_launched = false;
        detection_made = false; 
        missile_pos = [0 0];
        
        % Initialize target parameters
        target_range = app.zoomLevel + 10;
        target_angle = 270;
        target_height = 3;

       while app.running && ishandle(fig)

    if paused
        set(app.statusText, 'String', 'STATUS: PAUSED', 'ForegroundColor', 'y');
        pause(0.1);
        continue;  % Skip the rest of this loop iteration
    end

    if resetRequested
        % Clear plots and reset variables
        clearpoints(app.sweep_line);
        clearpoints(app.target_path);
        clearpoints(app.missile_path);
        set(app.target_dot, 'XData', NaN, 'YData', NaN);
        set(app.missile_dot, 'XData', NaN, 'YData', NaN);
        resetRequested = false;
        disp('Radar Reset Executed');
        continue;
    end

    if abortRequested
        app.running = false;
        stopSound('all');
        set(app.statusText, 'String', 'STATUS: ABORTED', 'ForegroundColor', 'r');
        disp('Aborting Radar...');
        break;
    end

    % Optionally show/hide trails or logs based on flags
    if ~trailsVisible
        set(app.target_path, 'Visible', 'off');
        set(app.missile_path, 'Visible', 'off');
    else
        set(app.target_path, 'Visible', 'on');
        set(app.missile_path, 'Visible', 'on');
    end
            % Update sweep angle (15 RPM = 3.6° every 0.04s)
            theta = mod(theta + 3.6, 360); 
            
            % Complete scan detection
            if theta < 3.6 && app.running
                app.scanNumber = app.scanNumber + 1;
                updateTables();
            end
            
            % Update radar display
            clearpoints(app.sweep_line);
            addpoints(app.sweep_line, [0 deg2rad(theta)], [0 app.zoomLevel]);
            
            % Target Movement (linear approach)
            target_range = max(1, target_range - 1.2 * 0.04);
            [xt, yt] = pol2cart(deg2rad(target_angle), target_range);
            
            set(app.target_dot, 'XData', xt, 'YData', yt);
            addpoints(app.target_path, xt, yt);
            
            % --- Target Detection and Missile Launch Logic ---
detected = abs(mod(theta - target_angle + 180, 360) - 180) < 3 && ...
           target_range <= app.zoomLevel;
if detected && ~detection_made
    detection_made = true;

    % === IFF Check ===
    target_ID = "XYZ123";  % Simulated target ID
    home_ID = "ABC999";    % Friendly ID

    if strcmp(target_ID, home_ID)
        msgbox('Object detected is a FRIEND. No action required.', 'IFF Status');
    else
        % FOE Detected
        try
            playSound('siren');
        catch
            warning('siren not found or playSound not defined.');
        end

        try
            blinkLED(app.alertLED);  % Blink alert LED (custom function)
        catch
            warning('LED blink function or alertLED handle missing.');
        end

        uiwait(msgbox('ENEMY DETECTED!', 'Threat Alert', 'warn'));

        % Prompt for missile launch
        permission = questdlg('Launch missile?', 'Permission to Fire', 'Yes', 'No', 'No');
        if strcmp(permission, 'Yes')
            missile_launched = true;
            missile_phase = "ascend";
            missile_pos = [0, 0];  % Launch from center
        else
            try
                stopSound('siren');
            catch
                warning('stopSound not available or siren not playing.');
            end

            try
            blinkLED(app.readyLED);  % Blink ready LED (custom function)
        catch
            warning('LED blink function or alertLED handle missing.');
            end

        end
    end
end

% --- Missile Guidance Logic ----

if missile_launched && target_range > 0
    switch missile_phase
        case "ascend"
            % Move missile vertically upward until it reaches target height
            missile_pos(2) = missile_pos(2) + app.missileSpeed * 0.05;

            % Check if missile is close enough to target height
            if abs(missile_pos(2) - target_height) < 1
                missile_phase = "cruise";  % Switch to next phase
            end

       case "cruise"
    % Dynamically recompute direction towards the current target position
    delta = [xt, yt] - missile_pos;
    distance = norm(delta);

    if distance > 1
        direction = delta / distance;  % Unit vector toward current target
        missile_pos = missile_pos + (app.missileSpeed * 0.05) * direction;
    else
        % If missile very close, stop adjusting
        missile_pos = [xt, yt];
    end


    % --- Update Missile Position on GUI ---
    set(app.missile_dot, 'XData', missile_pos(1), 'YData', missile_pos(2));
    addpoints(app.missile_path, missile_pos(1), missile_pos(2));
end

    % --- Collision Detection ---
    target_range = norm([xt, yt]);  % or your radar distance calculation

if norm([xt yt] - missile_pos) < 1.5
                    stopSound('siren');
                    playSound('buzzer');
                    set(app.explosion_effect, 'XData', xt, 'YData', yt, 'Visible', 'on');
                    msgbox('Target Destroyed!', 'Impact Confirmed', 'help');
                    pause(0.5);
                    set(app.explosion_effect, 'Visible', 'off');
                    missile_launched = false;
                    target_range = -10;
                end
end

drawnow limitrate;
pause(0.04);
t = t + 0.04;
       end
        
       function updateTables()
            % Update target table
            newTargetData = [app.scanNumber, target_range, target_angle, target_height];
            app.targetHistory = [app.targetHistory; newTargetData];
            set(app.targetTable, 'Data', app.targetHistory(max(1,end-4):end,:));
            
            % Update missile table if active
            if missile_launched
                [missile_ang, missile_r] = cart2pol(missile_pos(1), missile_pos(2));
                missile_ht = 3;
                newMissileData = [app.scanNumber, missile_r, rad2deg(missile_ang), missile_ht];
                app.missileHistory = [app.missileHistory; newMissileData];
                set(app.missileTable, 'Data', app.missileHistory(max(1,end-4):end,:));
                
                % Update height comparison table
                height_diff = abs(target_height - missile_ht);
                newHeightData = [app.scanNumber, target_height, missile_ht, height_diff];
            else
                newHeightData = [app.scanNumber, target_height, NaN, NaN];
            end
            
            app.heightHistory = [app.heightHistory; newHeightData];
            set(app.heightTable, 'Data', app.heightHistory(max(1,end-4):end,:));
        end
    end

   

    function stopSweep(~,~)
        app.running = false;
        set(app.sweepButton, 'Enable', 'on');
        set(app.stopButton, 'Enable', 'off');
        set(app.statusText, 'String', 'STATUS: STANDBY', 'ForegroundColor', 'r');
        stopSound('siren');
    end

    function updateZoom(~,~)
        app.zoomLevel = get(app.zoomSlider, 'Value');
        app.pax.RLim = [0 app.zoomLevel];
    end

    function updateMissileSpeed(~,~)
        app.missileSpeed = get(app.missileSpeedSlider, 'Value');
    end

    function updateSoundVolume(app)
        app.soundVolume = get(app.soundSlider, 'Value');
    end


    function playSound(soundType)
    try
        switch soundType
            case 'siren'
                [y, fs] = audioread('siren.mp3');
                sound(y, fs);
            case 'buzzer'
                [y, fs] = audioread('buzzer.mp3');
                sound(y, fs);
            otherwise
                warning('Unknown sound type: %s', soundType);
        end
    catch
        warning('Could not play sound: %s.mp3. File may be missing or unreadable.', soundType);
    end
end


  
function stopSound(soundType)
    switch soundType
        case 'siren'
            clear sound;  % Stops all current sound (no separate handles used)

        case 'buzzer'
            clear sound;  % Same as above — stops current buzzer sound too

        case 'all'
            clear sound;  % Since sound() doesn't allow individual control, we stop all

        otherwise
            warning('Unknown sound type: %s', soundType);
    end
end


 

    function onCloseRequest(~,~)
        app.running = false;
        stopSound('all');
        delete(fig);
    end
end

 
     
    function toggleView(~,~)
    if ~isfield(app, 'viewMode')
        app.viewMode = '2D';
    end
    if strcmp(app.viewMode, '2D')
        app.viewMode = '3D';
        disp('Switched to 3D View (simulate effect)');
        set(app.toggleViewButton, 'String', 'Switch to 2D');
    else
        app.viewMode = '2D';
        disp('Switched to 2D View');
        set(app.toggleViewButton, 'String', 'Switch to 3D');
    end
    end

function abortEmergency(~,~)
    global app abortRequested;
    abortRequested = true;  % Used inside sweep loop to trigger shutdown
    set(app.alertLED, 'ForegroundColor', 'magenta');
    %set(app.launchButton, 'Enable', 'off');
    set(app.statusText, 'String', 'STATUS: ABORTED', 'ForegroundColor', 'r');
    disp('EMERGENCY ABORT TRIGGERED');
end

function saveData(~,~)
    global app;

   % Define timestamp and folder
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    folderName = 'RadarDataLogs';
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end
    prefix = fullfile(folderName, ['RadarData_' timestamp]);

    try
        % Validate and save target history
        if isfield(app, 'targetHistory') && ~isempty(app.targetHistory)
            writematrix(app.targetHistory, [prefix '_target.csv']);
        else
            warning('Target history is missing or empty.');
        end

        % Validate and save missile history
        if isfield(app, 'missileHistory') && ~isempty(app.missileHistory)
            writematrix(app.missileHistory, [prefix '_missile.csv']);
        else
            warning('Missile history is missing or empty.');
        end

        % Validate and save height comparison history
        if isfield(app, 'heightHistory') && ~isempty(app.heightHistory)
            writematrix(app.heightHistory, [prefix '_height.csv']);
        else
            warning('Height history is missing or empty.');
        end

        msgbox('Radar data saved successfully!', 'Save Complete');
        fprintf('Saved data to folder: %s\n', folderName);
    catch ME
        msgbox('Failed to save radar data. See Command Window for details.', 'Save Error', 'error');
        disp(getReport(ME));
    end
end


    function pauseRadar(~,~)
    global app paused;
    paused = ~paused;
    if paused
        disp('Radar Paused');
        set(app.pauseButton, 'String', 'Resume');
    else
        disp('Radar Resumed');
        set(app.pauseButton, 'String', 'Pause');
    end
    end

    function resetRadar(~,~)
    global app resetRequested;
    resetRequested = true;

    % Visual Feedback
    clearpoints(app.sweep_line);
    clearpoints(app.target_path);
    clearpoints(app.missile_path);
    set(app.target_dot, 'XData', NaN, 'YData', NaN);
    set(app.missile_dot, 'XData', NaN, 'YData', NaN);

    % Clear histories and table data
    app.targetHistory = [];
    app.missileHistory = [];
    app.heightHistory = [];
    set(app.targetTable, 'Data', {});
    set(app.missileTable, 'Data', {});
    set(app.heightTable, 'Data', {});

    disp('Radar Reset Executed');
end

    function toggleTrails(~, ~)
    global app trailsVisible;
    trailsVisible = ~trailsVisible;
    if trailsVisible
        set(app.trailsButton, 'String', 'Hide Trails');
    else
        set(app.trailsButton, 'String', 'Show Trails');
    end
    disp(['Trails visibility: ', num2str(trailsVisible)]);
    end

function toggleLogs(~, ~)
    global app logsVisible logsFig logsTimer logTable;

    logsVisible = ~logsVisible;

    if logsVisible
        % Open or bring to front
        if isempty(logsFig) || ~isvalid(logsFig)
            logsFig = figure('Name', 'Live Radar Logs', 'NumberTitle', 'off', ...
                'MenuBar', 'none', 'ToolBar', 'none', ...
                'Color', [0.1 0.1 0.1], 'Position', [300 300 600 400]);
        else
            figure(logsFig);
        end

        % Clear previous UI
        clf(logsFig);
        logPanel = uipanel(logsFig, 'Position', [0 0 1 1], 'BackgroundColor', [0.1 0.1 0.1]);

        % Create table
        logTable = uitable(logPanel, 'Units', 'normalized', 'Position', [0 0 1 1], ...
            'ColumnName', {'Scan', 'Target R', 'Target Az', 'Missile R', 'ΔH'}, ...
            'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w');

        % Start live update timer
        logsTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1, ...
            'TimerFcn', @(~, ~) updateLogTable(logTable, app));
        start(logsTimer);

        set(app.logsButton, 'String', 'Hide Logs');
    else
        % Stop and delete timer
        if ~isempty(logsTimer) && isvalid(logsTimer)
            stop(logsTimer);
            delete(logsTimer);
        end
        logsTimer = [];

        % Close log figure
        if isvalid(logsFig)
            close(logsFig);
        end
        logsFig = [];

        set(app.logsButton, 'String', 'Show Logs');
    end
end


function updateLogTable(logTable, app)
    % Get lengths of all histories
    rowsTarget = size(app.targetHistory, 1);
    rowsMissile = size(app.missileHistory, 1);
    rowsHeight = size(app.heightHistory, 1);
    maxRows = max([rowsTarget, rowsMissile, rowsHeight]);

    % Initialize with NaNs
    mergedData = nan(maxRows, 5);

    % Fill each column safely
    if rowsTarget > 0
        mergedData(1:rowsTarget, 1:3) = app.targetHistory(:, 1:3);
    end
    if rowsMissile > 0
        mergedData(1:rowsMissile, 4) = app.missileHistory(:, 2);
    end
    if rowsHeight > 0
        mergedData(1:rowsHeight, 5) = app.heightHistory(:, 4);
    end

    % Update the UI table
    if isvalid(logTable)
        set(logTable, 'Data', mergedData);
    end
end

function toggleTargetInfo(~, ~)
    % Toggle visibility flag
    if app.targetInfoPanelVisible
        set(app.targetInfoPanel, 'Visible', 'off');
        set(app.toggleInfoButton, 'String', 'Show Target Info');
    else
        set(app.targetInfoPanel, 'Visible', 'on');
        set(app.toggleInfoButton, 'String', 'Hide Target Info');
    end

    % Toggle the state
    app.targetInfoPanelVisible = ~app.targetInfoPanelVisible;
end

function takeSnapshot(~, ~)
    [file, path] = uiputfile('radar_snapshot.png', 'Save Snapshot As');
    if isequal(file, 0)
        return; % user canceled
    end
    F = getframe(gcf);  % or use app.fig if defined
    imwrite(F.cdata, fullfile(path, file));
    msgbox('Snapshot saved successfully!', 'Success', 'modal');
end


   function blinkLED(led)
    for i = 1:4
        set(led, 'Visible', 'off'); pause(1);
        set(led, 'Visible', 'on');  pause(1);
    end
    end

    