# 3/3/2017 modified from Wanyu_3_24_2017_2AB, fixed ITI=6s, add white noise back.
# shorten reward/unreward window to 1.5s. whitenoise 1s
# 3/4/2017 ITI=3s, reward=2.9s, response window=2s, noise=3s with white noise=1s. adjust 'double n...  & conMiss...' location; delete nothing{} in noise event
# 3/5/2017 add rewared rate
# 3/27/2017 get rid of white noise for no_reward event, couple white noise with nolick period
#-------HEADER PARAMETERS-------#
scenario = "2arm bandit, exp nolick, Wanyu_3_27_2017_2AB";
active_buttons = 3;							#how many response buttons in scenario
button_codes = 1,2,3;	
target_button_codes = 1,2,3;
response_logging = log_all;				#log all trials
response_matching = simple_matching;	#response time match to stimuli
default_all_responses = true;
begin;
#-------SOUND STIMULI-------#
sound {
	wavefile { filename ="tone_5000Hz_0.2Dur.wav"; preload = true; };
} go;

sound {
	wavefile { filename ="wanyu_white_noise_8s.wav"; preload=true; };
} whitenoise;

#-------SDL EVENTS ('TRIALS')-------#

trial {
	all_responses = false;	#first_response, but ignore the responses before stimulus_time_in
	trial_type = first_response;
	trial_duration = 2000;
	sound go;
	code=5; #port_code=0.5;
	# stimulus_time_in = 0;   # assign response that occur
  # stimulus_time_out = 100; # 0.5-2 s after start of stimulus
	target_button = 2,3;   
} response_window;

trial {
	trial_type = fixed;
	trial_duration = 2900;	#3sec to drink
	nothing {} reward_event;
	code=6;
} reward;

trial {
	trial_type = fixed;
	trial_duration = 3000;
	
	nothing {} norewardevent;
	code=7; #port_code=2;
	#	response_active = true;
} noise;

trial {
	trial_type = fixed;
	trial_duration = 1000;
	nothing {} pause_event;
	code=8;
} pause;



trial { #INTERVAL BETWEEN REWARD PULSES
   trial_type = fixed;
	trial_duration = 100; #to prevent conflicts on the output port
		nothing {} ;
	code=100;
}interpulse;


trial { #INTERTRIAL NO-LICK PERIOD  
	trial_type = fixed;
   trial_duration = 3000; 
sound whitenoise;
	code=90;
} noLicks;

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
int nTrials_hiP_totalIndex = parameter_window.add_parameter("Hr_Hit");
int trialnumIndex = parameter_window.add_parameter("Trial num");
int hiP_rateIndex=parameter_window.add_parameter("hiP_rate");
int state_Index=parameter_window.add_parameter("State");
int block_Index=parameter_window.add_parameter("Hr site");
int geo_Index=parameter_window.add_parameter("Geo_sample");
int re_Index=parameter_window.add_parameter("Reward Rate");
# int expIndex=parameter_window.add_parameter("ITI(ms)");
#CONFIGURE OUTPUT PORT
output_port port = output_port_manager.get_port(1);




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

preset int waterAmount_left = 18;    #   14~3.3uL 2/14/2017
preset int waterAmount_right = 16;

double reward_threshold = double(0); #threshold for reward, will change later in the code

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

double i_geo=double(0) ;  # block switch index
int block_length=0;
double  ii=double(1);  # sample from geometric distribution
double m=double(0);
#-------------TRIAL STRUCTURE------------------------------




loop
	int i = 0
	
until
	consecMiss >= max_consecMiss
begin
	logfile.add_event_entry(string(block));    # indicate high reward side


# sample from truncated geometric distribution, update only after switch of high reward port
	 if i_geo==double(0) && block_length==0 then
		double shift_threshold = 1.000-0.0909; # sucess probability = 1/(mean+1),  0.0909
		m=ceil(double(950)*random());
		ii=double(0); #reset ii
		double cp=pow(shift_threshold,ii)*(double(1)-shift_threshold)*double(1000);# cummulative probablity
			loop until m<cp
			begin
			ii=ii+double(1);
			cp=cp+pow(shift_threshold,ii)*(double(1)-shift_threshold)*double(1000);
			end;
	 end;


	#RESPONSE WINDOW AND REWARD DETERMINATION
state="response_window";
parameter_window.set_parameter(state_Index,state);	
	double n=random();
response_window.present();

	if response_manager.response_count()>0 then   # lick, not miss
	
		if 		(response_manager.last_response()==2) then side = "left";
		elseif 	(response_manager.last_response()==3) then side = "right";
		end;

		
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
			noise.present(); # no reward
			if	side=="right" then
				right_no_r = right_no_r + 1;
				parameter_window.set_parameter(right_no_rIndex,string(right_no_r));
			else
				left_no_r = left_no_r +1;
				parameter_window.set_parameter(left_no_rIndex,string(left_no_r));
			end;
		end;
		consecMiss = 0;
		parameter_window.set_parameter(consecmissIndex,string(consecMiss));	
	else 
		state="miss pause";
	   parameter_window.set_parameter(state_Index,state);
		pause.present(); #no response --> next trial	
		consecMiss = consecMiss + 1;
		parameter_window.set_parameter(consecmissIndex,string(consecMiss));
	end;

# no lick period
	
	int nLicks = 1; #initialize 	
loop until nLicks == 0 
begin
	
double expval=0.1;     # Zador biorxiv (2016)
	loop 
			expval=1.5-1.0/2.0*log(random())    # min-1/mu*log(random)
		until
			expval<1.5+3.0    # truncateat 3s
		begin		
			expval=1.5-1.0/2.0*log(random())    #1 minimum
		end;
		
	noLicks.set_duration(int(1000.0*expval));
	state="no lick";
	parameter_window.set_parameter(state_Index,state + "("+string(expval)+")");
	noLicks.present();
	nLicks = response_manager.response_count(); #wait until no licks within 2-sec
end;




parameter_window.set_parameter(block_Index,string(block));   # display high reward side
block_length=block_length+1;   # update trials within current block
	#PROBABILITY BLOCK SWITCH

	if nTrials_hiP>=10 then  
		if i_geo==ii then
			block_length=0; # reset  trial number within current block
			# switch block
			if block==1 then block = 2
			else block = 1
			end;	
			nTrials_hiP = 0; # reset count
			i_geo=double(0); # reset i_geo 
		else i_geo=i_geo+double(1);
		end;	
	end;
	parameter_window.set_parameter(geo_Index,"ii="+string(ii)+" i_geo="+string(i_geo)+"m"+string(m)); # display i_geo
i = i+1;	
n_trial=i;	# total trial number
parameter_window.set_parameter(trialnumIndex,string(i) + " ("+string(nTrials_hiP)+" hit/block)");	


parameter_window.set_parameter(hiP_rateIndex,string(nTrials_hiP_total*100/n_trial)+"%");
if left_no_r+left_r+right_r+right_no_r>0 then
parameter_window.set_parameter(re_Index,string(100*(left_r+right_r)/(left_no_r+left_r+right_r+right_no_r))+"%");
end
end;

#----------------------record ITI---------------------
output_file ofile = new output_file;    # let the trial end without using 'quit'
string asd = date_time("mmddhhnn");

	ofile.open("C:\\Users\\KWANLAB\\Desktop\\Presentation\\logfiles\\logstats_wanyu_accuracy"+asd+".txt");
	#ofile.open_append("logstats_ITI.txt"); 
	ofile.print("\n\t Rig 2 ");
	ofile.print("\n\tTotal trial number");
	ofile.print("\n\t" + string(n_trial));
	ofile.print("\n\tHigh reward hit (total)");
	ofile.print("\n\t" + string(nTrials_hiP_total));
	ofile.print("\n\tHigh reward accuracy percentage (%)");
	ofile.print("\n\t" + string(nTrials_hiP_total*100/n_trial)+"%");	
	ofile.print("\n\tReward rate (%)");
	ofile.print("\n\t"+string(100*(left_r+right_r)/(left_no_r+left_r+right_r+right_no_r))+"%");
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
	
	
	

