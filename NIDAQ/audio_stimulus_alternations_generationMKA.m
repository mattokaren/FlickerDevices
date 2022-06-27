stimuli_on_duration=input('Specify Each Stimuli Block Duration in Seconds: ');
no_stimuli_duration=input('Specify Each No-Stimulus (Baseline) Block Duration in Seconds: ');

num_stimuli_on_blocks=input('Specify Number of Stimuli Blocks: ');

sound_freq=input('Specify Sound Frequency in Hertz: '); %Obtain desired sound frequency in Hertz from the keyboard

recording_duration_minutes=input('Specify Entire Recording Duration in Minutes: '); %Obtain desired stimuli duration from the keyboard

recording_duration_seconds = recording_duration_minutes*60;

rfreq=2*pi*sound_freq;                      %Convert sound frequency to radian frequency
    
sample_rate = 24000;

% specify stimuli_on timepoints and signals
Ts=0:1/sample_rate:stimuli_on_duration; % time points for non-baseline portion of alternations
sound_signal= 10*cos(rfreq*Ts);                       %Calculate the cosine for the entire sound duration; 10V is the max analog output
LED_signal = 5; % LED signal will drive the TTL-responsive (5V) FET connected to the power source

num_loops = round(recording_duration_seconds/((stimuli_on_duration+no_stimuli_duration)*num_stimuli_on_blocks));

if num_loops ~= recording_duration_seconds/((stimuli_on_duration+no_stimuli_duration)*num_stimuli_on_blocks)
    display(sprintf('actual recording duration will be %.1f minutes', round(10*num_loops*((stimuli_on_duration+no_stimuli_duration)*num_stimuli_on_blocks)/60)/10))
end

stimuli_signal_final = zeros(num_stimuli_on_blocks*length(Ts),2); %pre-allocate for speed

for i = 1:num_stimuli_on_blocks
    click_freq = input(sprintf('Specify Number of Sound Clicks/LED Blinks Per Second for Stimuli Block #%d: ', i));    
    
    % for each stimuli block, create source vectors
    if click_freq ~= 0        
        stimuli_duty_cycle = input(sprintf('Specify Duty Cycle of Stimuli for Stimuli Block #%d (ex. 50 means 50 Percent): ', i));    
        
        display(sprintf('Stimuli Block #%d Source Vector Is Being Generated..', i))
        
        period_pulse = 1/click_freq; % in ms; 40 clicks/s
        pulse_width = (stimuli_duty_cycle/100)*period_pulse; % pulse width    

        % pulse train mask for sound 
        D_1 = pulse_width/2:1/click_freq:max(Ts); % 50Hz repetition freq; note: we are starting D at width/2 instead of 0 to shift the pulse train to the right by width/2 and thus start the train at 0
        pulse_train_mask = pulstran(Ts, D_1, 'rectpuls', pulse_width);
        
        % mask the sound signal with the pulse train mask
        sound_signal_masked = sound_signal.*pulse_train_mask;        
    else        
        display(sprintf('Stimuli Block #%d Source Vector Is Being Generated..', i))
        
        pulse_train_mask_2 = ones(1, length(Ts));
        
        % mask the sound and LED signals with the pulse train mask
        sound_signal_masked = sound_signal;        
    end
    
    % mask the LED signal with the pulse train mask
    LED_signal_masked = LED_signal*pulse_train_mask;
    
    % store source vector into stimuli_signal_final vector
    stimuli_signal_final((i-1)*length(Ts)+1:i*length(Ts), 1) = sound_signal_masked(:);
    stimuli_signal_final((i-1)*length(Ts)+1:i*length(Ts), 2) = LED_signal_masked(:);
end

filename = input('Specify Filename To Save Generated Stimuli Source Vectors In Single Quatation Marks: ');
save(filename,'stimuli_signal_final', 'no_stimuli_duration', 'num_stimuli_on_blocks', 'num_loops', 'sample_rate');