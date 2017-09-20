#  1/27/2017: incoporate no lick period (1s) followed by ITI (~exp.) , use pure tone as go; white noise ; modify from 1/21/2017 version, incorporate go_cue into response window, ITI has exponential distribution
# 2/16/2017  eliminate white noise, since a quater of neurons in M2 will respond to auditory cue, it's better not have it
#2/21/2017 silence exp. ITI; add state 

#-------HEADER PARAMETERS-------#
scenario = "2arm bandit, exp ITI & no lick peroid, Wanyu_2_21_2017_no_lick";
active_buttons = 3;							#how many response buttons in scenario
button_codes = 1,2,3;	
target_button_codes = 1,2,3;
response_logging = log_all;				#log all trials
response_matching = simple_matching;	#response time match to stimuli
default_all_responses = true;
begin;
#-------SOUND STIMULI-------#
sound {
	wavefile { filename ="GO_CUE_5KHz_0.1s.wav"; preload = true; };
} go;



#-------SDL EVENTS ('TRIALS')-------#

trial {
	all_responses = false;	#first_response, but ignore the responses before stimulus_time_in
	trial_type = first_response;
	trial_duration = 2100;
	sound go;
	code=5; #port_code=0.5;
	# stimulus_time_in = 0;   # assign response that occur
  # stimulus_time_out = 100; # 0.5-2 s after start of stimulus
	target_button = 2,3;   
} response_window;

trial {
	trial_type = fixed;
	trial_duration = 3000;	#3sec to drink
	nothing {} reward_event;
	code=6;
} reward;

trial {
	trial_type = fixed;
	trial_duration = 3000;
	
	nothing {} norewardevent;
	code=7; #port_code=2;
	#	response_active = true;
} blank;

trial {
	trial_type = fixed;
	trial_duration = 3000;
	nothing {} pause_event;
	code=8;
} pause;



trial { #INTERVAL BETWEEN REWARD PULSES
   trial_type = fixed;
   trial_duration = 100; #to prevent conflicts on the output port
}interpulse;


trial { #INTERTRIAL NO-LICK PERIOD  
	trial_type = fixed;
   trial_duration = 2000; 
}noLicks;

trial {
   save_logfile {
		filename = "temp.log"; 	# use temp.log in default logfile directory
	};									#save logfile during mid-experiment
}quicksave;



 


#--------PCL---------------
begin_pcl;

#HEADER


#SETUP TERMINAL WINDOW
term.print("Starting time:");
term.print(date_time());
logfile.add_event_entry(date_time());
display_window.draw_text("Initializing...");

#SETUP PARAMETER WINDOW
parameter_window.remove_all();
int left_rIndex = parameter_window.add_parameter("Left Reward");
int left_no_rIndex = parameter_window.add_parameter("Left No Reward");
#int left_missIndex = parameter_window.add_parameter("Left Miss");
# int left_correctIndex= parameter_window.add_parameter("Left Correct"); # choose left side with high rewarded posibility
# int left_incorrectIndex=parameter_window.add_parameter("Left Incorrect");
int right_rIndex = parameter_window.add_parameter("Right Reward");
int right_no_rIndex = parameter_window.add_parameter("Right No Reward");
#int right_missIndex= parameter_window.add_parameter("Right Miss");
#int right_correctIndex= parameter_window.add_parameter("Right Correct"); # choose right side with high rewarded posibility
#int right_incorrectIndex=parameter_window.add_parameter("Right Incorrect");

int consecmissIndex = parameter_window.add_parameter("Consec Miss");
int nTrials_hiP_totalIndex = parameter_window.add_parameter("High Reward Hit");
int trialnumIndex = parameter_window.add_parameter("Trial num");
int hiP_rateIndex=parameter_window.add_parameter("hiP_rate");
int state_Index=parameter_window.add_parameter("State");
# int expIndex=parameter_window.add_parameter("ITI(ms)");
#CONFIGURE OUTPUT PORT
output_port port = output_port_manager.get_port(1);


# define an array to store expval
array <double> expval_store[0]; 

#INITIALIZE VARIABLES
int block = int(ceil(random()*double(2)));
int button = 0; #temporary for debug
int nTrials_hiP = 0; #trials passed in current block
int nTrials_hiP_total = 0;
preset int max_consecMiss = 20;                                                                                 ; #triggers end session, for mice, set to 20
int consecMiss = 0;

int left_r=0;
int left_no_r=0;
int left_miss=0;
int left_correct=0;
int left_incorrect=0;
int right_r=0;
int right_no_r=0;
int right_miss=0;
int right_correct=0;
int right_incorrect=0;
int n_trial=0;

preset int waterAmount_left = 20;    #   14~3.3uL 2/14/2017
preset int waterAmount_right = 20;

double reward_threshold = double(0); #threshold for reward
double shift_threshold = 1/11; # sucess probability = 1/mean
string side;
string state;
##...to be continued

##SUBROUTINE
sub #DELIVER REWARD AND UPDATE LASTRESPTIME, LICK COUNT, REPS, AND PARAMETER WINDOW 
rewardDelivery(string var_side)
begin
	int code ; int pulse_dur; 
	if var_side=="left" then
		code = 4; pulse_dur = waterAmount_left;     # this code is set in digital hard drive. it has to be 4 for left and 8 for right (this 'code' is different from event code)
   elseif var_side=="right" then
		code = 8; pulse_dur = waterAmount_right; 
	end;
	state="reward";
	parameter_window.set_parameter(state_Index,state);
	port.set_pulse_width(pulse_dur);
	port.send_code(code);		#give water reward to right
	interpulse.present();
	port.send_code(code);	#second pulse
	reward.present();
end;




#-------------TRIAL STRUCTURE------------------------------
loop
	int i = 0
until
	consecMiss >= max_consecMiss
begin
	logfile.add_event_entry(string(block));    # indicate high reward side

	#RESPONSE WINDOW AND REWARD DETERMINATION
state="response_window";
parameter_window.set_parameter(state_Index,state);	
response_window.present();
	
	if response_manager.response_count()>0 then   # lick, not miss
		consecMiss = 0;
		parameter_window.set_parameter(consecmissIndex,string(consecMiss));	
		if 		(response_manager.last_response()==2) then side = "left";
		elseif 	(response_manager.last_response()==3) then side = "right";
		end;

		double n=random();
		if 		(block==1 && side=="left") || (block==2 && side=="right") then
						reward_threshold = 0.7; 
						nTrials_hiP = nTrials_hiP+1; # nTrials on high-reward side 
						nTrials_hiP_total = nTrials_hiP_total+1;
						parameter_window.set_parameter(nTrials_hiP_totalIndex,string(nTrials_hiP_total));
		elseif 	(block==2 && side=="left") || (block==1 && side=="right") then
						reward_threshold = 0.1;
		end;

		if n <= reward_threshold then
			rewardDelivery(side);    #subrountine    give water
			if	side=="right" then
				right_r = right_r + 1;
				parameter_window.set_parameter(right_rIndex,string(right_r));

			else
				left_r = left_r +1;
				parameter_window.set_parameter(left_rIndex,string(left_r));

			end;
		else
			state="no reward";
	      parameter_window.set_parameter(state_Index,state);
			blank.present(); # no reward
			if	side=="right" then
				right_no_r = right_no_r + 1;
				parameter_window.set_parameter(right_no_rIndex,string(right_no_r));
			else
				left_no_r = left_no_r +1;
				parameter_window.set_parameter(left_no_rIndex,string(left_no_r));
			end;
		end;
	else 
		state="miss pause";
	   parameter_window.set_parameter(state_Index,state);
		pause.present(); #no response --> next trial	
		consecMiss = consecMiss + 1;
		parameter_window.set_parameter(consecmissIndex,string(consecMiss));
	end;

#INTERTRIAL NO LICK PERIOD
int nLicks = 1; #initialize 	
loop until nLicks == 0 
begin
	state="no lick period";
	parameter_window.set_parameter(state_Index,state);
	noLicks.present();
	nLicks = response_manager.response_count(); #wait until no licks within 2-sec
end;

	#PROBABILITY BLOCK SWITCH
	double m=random();
	if nTrials_hiP>=10 && m<=shift_threshold then   # geometric distribution
		if block==1 then block = 2
		else block = 1
		end;	
		nTrials_hiP = 0; # reset count
	end;
# parameter_window.set_parameter(trialnumIndex,string(i) + " ("+string(nTrials_hiP_total)+" hiP_hi total)");	
i = i+1;	
n_trial=i;	
parameter_window.set_parameter(trialnumIndex,string(i) + " ("+string(nTrials_hiP)+" hiP_hit per block)");	

parameter_window.set_parameter(hiP_rateIndex,string(nTrials_hiP_total*100/n_trial)+"%"+string(m));

end;

#----------------------record ITI---------------------
output_file ofile = new output_file;    # let the trial end without using 'quit'
string asd = date_time("yymmddhhmm");
	ofile.open("C:\\Users\\KWANLAB\\Desktop\\Presentation\\logfiles\\logstats_wanyu_accuracy.txt");
	#ofile.open_append("logstats_ITI.txt"); 
	ofile.print("\nStarting time:");
	ofile.print(date_time());
	ofile.print("\n\tRig 2");
	ofile.print("\n\tTotal trial number");
	ofile.print("\n\t" + string(n_trial));
	ofile.print("\n\tHigh reward hit (total)");
	ofile.print("\n\t" + string(nTrials_hiP_total));
	ofile.print("\n\tHigh reward accuracy percentage (%)");
	ofile.print("\n\t" + string(nTrials_hiP_total*100/n_trial)+"%");	
	ofile.print("\n\tConsecutive Miss");
	ofile.print("\n\t" + string(consecMiss));
	
	ofile.print("\n\tRight reward");
	ofile.print("\n\t" + string(right_r));
	ofile.print("\n\tRight no reward");
	ofile.print("\n\t" + string(right_no_r));
	ofile.print("\n\tRight total");
	ofile.print("\n\t" + string(right_no_r+right_r));
	
	ofile.print("\n\tLeft reward");
	ofile.print("\n\t" + string(left_r));
	ofile.print("\n\tLeft no reward");
	ofile.print("\n\t" + string(left_no_r));
	ofile.print("\n\tLeft total");
	ofile.print("\n\t" + string(left_no_r+left_r));
	ofile.print("\n\tLeft water per trial");
	ofile.print("\n\t" + string(waterAmount_left));
	ofile.print("\n\tRight water per trial");
	ofile.print("\n\t" + string(waterAmount_right));
	ofile.print("\nEnding time:");
	ofile.print(date_time());
	ofile.close();
	

