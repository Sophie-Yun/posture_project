%% Pre-experiment preparation
% Clear the workspace and the screen
sca;
close all;
clear;

% set subject id
%sub_id = 7;
sub_id = input('Subject ID: ','s'); %YY

% Check if subject id has been used
% if exist(sprintf('behavioral_data_folder/pose_data_%02d.mat',sub_id), 'file') == 2
if exist(sprintf('behavioral_data_folder/pose_data_%s.mat',sub_id), 'file') == 2 %YY
    assert(false,'This sub_id has been used. Set a new sub_id first!!');
end
% Need to run the following line if using Macbook, because of sync
% failures. If using windows computer, the following line should be removed
% for precise timing control.
Screen('Preference', 'SkipSyncTests', 1) 
% PsychDebugWindowConfiguration;
 
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
inc = white - grey;

% Open an on screen window
HideCursor; %YY
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
ifi = Screen('GetFlipInterval', window);
[xCenter, yCenter] = RectCenter(windowRect);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%% Load stimulus path and presentation time information
% load image path & names
image_folder = 'figures/demo_image/new_render/';
%trial_data = load(sprintf('trial_order_table/design_tb_option1_sub%02d',sub_id));%YY
trial_data = load(sprintf('trial_order_table/design_tb_option1_sub%s',sub_id)); 
practice_trial_data = load('practice_design_tb_12142021_new_render.mat');

% total number of stimuli to use.
num_image = size(trial_data.design_tb.Image,1);
% fixation time (second)
init_fixation_time = 0.3; 
init_fixation_time_frames = round(init_fixation_time / ifi);
in_between_fixation_time = 0.1; 
in_between_fixation_time_frames = round(in_between_fixation_time / ifi);
in_between_time = 0.5; % Time between real target image and the synthetic choice image
in_between_time_frames = round(in_between_time / ifi);
mask_time = 0.5;
mask_time_frames = round(mask_time / ifi);
% set image size 
image_pix_size = screenYpixels/3; % on my laptop this is 900 / 3 = 300;
% set text size
Screen('TextSize', window, floor(screenYpixels/40));

%% Define fixation cross
fixCrossDimPix = 40;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
%% Practice block
num_practice_trials = length(practice_trial_data.design_tb.Image);
line1 = 'Pose Matching Experiment.';
line2 = '\n Each time, you will see a natural image of a person, followed by a noise patch and a synthetic image of a person.';
line3 = '\n The task is to decide whether human poses in natural and synthetic images are the same,';
line4 = '\n regardless of the positions of the human bodies in two images.';
line5 = '\n\n Press any key to continue to practice trials before starting the experiment.';
DrawFormattedText(window, [line1 line2 line3 line4 line5], 'center', 'center', 0);
vbl = Screen('Flip', window);
pause(2);
[keyIsDown,secs, keyCode] = KbCheck;
while ~keyIsDown 
    [keyIsDown,secs, keyCode] = KbCheck;
end

line1 = 'Practice session (4 trials).';
line2 = '\n Press "s" if you think real and synthetic poses are the same. Press "d" if you think they are different.';
line3 = '\n\n After you finish a trial, press SPACE bar to continue to the next trial.'; %YY
line4 = '\n\n Now, press SPACE bar to start the first practice trial.';
DrawFormattedText(window, [line1 line2 line3 line4], 'center', 'center', 0);
vbl = Screen('Flip', window);
pause(3);
[keyIsDown,secs, keyCode] = KbCheck;
while ~keyIsDown || ~any(strcmpi(KbName(keyCode),'space'))
    [keyIsDown,secs, keyCode] = KbCheck;
end
practice_trial_order = {'the same','the same','different','different'};
practice_trial_order_press = {'s','s','d','d'};
for i = 1:num_practice_trials
    % Draw init fixation
    Screen('DrawLines', window, allCoords, 4, white, [xCenter yCenter], 2);
    vbl = Screen('Flip', window);
    
    % Load real image, mask image, and synthetic image
    real_image_path = [image_folder 'practice_trials/real/' sprintf('%05d_sq.png', practice_trial_data.design_tb.Image(i))];
    syn_image_path = [image_folder 'practice_trials/synthetic/' sprintf('%05d_m.png', practice_trial_data.design_tb.Choice(i))];
    real_image = imresize(imread(real_image_path),[image_pix_size,nan]);
    mask_image = imscramble(real_image);
    syn_image = imresize(imread(syn_image_path),[image_pix_size,nan]);
    pres_time = 1000; % set practice pres time to 1000ms for practice trials only
    pres_frames = round(pres_time / 1000 / ifi); 
    
    % Make the image into a texture
    realimageTexture = Screen('MakeTexture', window, real_image);
    maskimageTexture = Screen('MakeTexture', window, mask_image);
    synimageTexture = Screen('MakeTexture', window, syn_image);
    % Draw real texture
    Screen('DrawTexture', window, realimageTexture, [], [], 0);
    vbl = Screen('Flip', window, vbl+(init_fixation_time_frames - 0.5) * ifi);
    
    % Draw mask texture
    Screen('DrawTexture', window, maskimageTexture, [], [], 0);
    vbl = Screen('Flip', window, vbl+(pres_frames - 0.5) * ifi);
    
    % Draw in between fixation
    Screen('DrawLines', window, allCoords, 4, white, [xCenter yCenter], 2);
    vbl = Screen('Flip', window, vbl+(mask_time_frames - 0.5) * ifi);
    
    % Draw syn texture and flip to screen
    Screen('DrawTexture', window, synimageTexture, [], [], 0);
    line1 = ['The poses in natural and synthetic images are ' practice_trial_order{i} ' in this trial.'];
    line2 = ['\n Therefore, you should press "' practice_trial_order_press{i} '" to continue.'];
    DrawFormattedText(window, [line1 line2], 'center', screenYpixels*0.15, 0);
    vbl = Screen('Flip', window, vbl+(in_between_fixation_time_frames - 0.5) * ifi);

    % wait for key input (same or different)
    [keyIsDown,secs, keyCode] = KbCheck;
    while ~keyIsDown || ~any(contains(KbName(keyCode),{'s','d'},'IgnoreCase',true))
        [keyIsDown,secs, keyCode] = KbCheck;
    end
    
    % wait for space bar before continue to next
    line1 = ['\n After you make the choice ("s" or "d"), now press SPACE bar to continue to next trial.']; %YY
    DrawFormattedText(window, line1, 'center', screenYpixels*0.15, 0);
    vbl = Screen('Flip', window);
    [keyIsDown,secs, keyCode] = KbCheck;
    while ~keyIsDown || ~any(strcmpi(KbName(keyCode),'space'))
        [keyIsDown,secs, keyCode] = KbCheck;
    end
end

%% Main Experiment
% iterate through all stimuli
key_pressed = [];
target_start_time_list = [];
target_end_time_list = [];
choice_start_time_list = [];
key_press_time_list = [];
line1='Experiment (400 trials).';
line2='\n Press "s" if real and synthetic poses are the same. Press "d" if they are different.';
line3='\n If two poses are the same but they have different positions/sizes, you should press "d".';
line4='\n Natural image display time may be shorter than the practice trials.';
line5='\n Synthetic image are constantly present before you press "s" or "d".';
line6='\n Do you best to judge whether human poses are same or different in natural and synthetic images.';
line7='\n\n After you finish a trial, press SPACE bar to continue to the next trial.';
line8='\n\n Now, press SPACE bar to start the first trial.';
line9='\n\n Press Esc if you want to quit the experiment halfway.';
DrawFormattedText(window, [line1 line2 line3 line4 line5 line6 line7 line8 line9], 'center', 'center', 0);
vbl = Screen('Flip', window);
pause(3);
[keyIsDown,secs, keyCode] = KbCheck;
while ~keyIsDown || ~any(strcmpi(KbName(keyCode),'space'))
    [keyIsDown,secs, keyCode] = KbCheck;
end
exitNow = false;
for i = 1:num_image
    % Draw fixation
    Screen('DrawLines', window, allCoords, 4, white, [xCenter yCenter], 2);
    vbl = Screen('Flip', window);
    
    % Load real image, mask image, and synthetic image
    real_image_path = [image_folder 'main_experiment/real/all/' sprintf('%05d_sq.png', trial_data.design_tb.Image(i))];
    syn_image_path = [image_folder 'main_experiment/synthetic/' sprintf('%05d_m.png', trial_data.design_tb.Choice(i))];
    real_image = imresize(imread(real_image_path),[image_pix_size,nan]);
    mask_image = imscramble(real_image);
    syn_image = imresize(imread(syn_image_path),[image_pix_size,nan]);
    pres_time = trial_data.design_tb.Time(i); %  in second(s)
    pres_frames = round(pres_time / 1000 / ifi); 
    
    % Make the image into a texture
    realimageTexture = Screen('MakeTexture', window, real_image);
    maskimageTexture = Screen('MakeTexture', window, mask_image);
    synimageTexture = Screen('MakeTexture', window, syn_image);
    
    % Draw real texture
    Screen('DrawTexture', window, realimageTexture, [], [], 0);
    vbl = Screen('Flip', window, vbl+(init_fixation_time_frames - 0.5) * ifi);
    target_start_time_list = [target_start_time_list vbl];
    
    % Draw mask texture
    Screen('DrawTexture', window, maskimageTexture, [], [], 0);
    vbl = Screen('Flip', window, vbl+(pres_frames - 0.5) * ifi);
    target_end_time_list = [target_end_time_list vbl];
    
    % Draw fixation
    Screen('DrawLines', window, allCoords, 4, white, [xCenter yCenter], 2);
    vbl = Screen('Flip', window, vbl+(mask_time_frames - 0.5) * ifi);
    
    % Draw syn texture and flip to screen
    Screen('DrawTexture', window, synimageTexture, [], [], 0);
    vbl = Screen('Flip', window, vbl+(in_between_fixation_time_frames - 0.5) * ifi);
    choice_start_time_list = [choice_start_time_list vbl];
    
    % wait for key input (same or different)
    [keyIsDown,secs, keyCode] = KbCheck;
    while ~keyIsDown || ~any(contains(KbName(keyCode),{'s','d','escape'},'IgnoreCase',true))
        [keyIsDown,secs, keyCode] = KbCheck;
    end
    if strcmpi(KbName(keyCode),'escape')
        exitNow = true;
    end
    key_pressed = [key_pressed; keyCode]; % optionally convert to key names with KbName(keyCode)
    key_press_time_list = [key_press_time_list secs];
    if exitNow
        break;
    end
    vbl = Screen('Flip', window);
    % wait for space bar before continue to next
    [keyIsDown,secs, keyCode] = KbCheck;
    while ~keyIsDown || ~any(strcmpi(KbName(keyCode),'space'))
        [keyIsDown,secs, keyCode] = KbCheck;
    end
end
ShowCursor; %YY
sca;
%% Save responses and parameters to file
%save(sprintf('behavioral_data_folder/pose_data_%02d.mat',sub_id),'choice_start_time_list','key_press_time_list','key_pressed','target_start_time_list','target_end_time_list','trial_data');
save(sprintf('behavioral_data_folder/pose_data_%s.mat',sub_id),'choice_start_time_list','key_press_time_list','key_pressed','target_start_time_list','target_end_time_list','trial_data'); %YY