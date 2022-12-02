clear all
close all
clc

x1 = xlsread('ecg_recording.xlsx'); % load the ECG signal from the file
x1 = x1(:,2);
fs = 250;              % Sampling rate 250Hz
N = length (x1);       % Signal length
t = [0:N-1]/fs;        %#ok<*NBRAK> % time index
figure(1)
subplot(2,1,1)
plot(t,x1)
xlabel('second');ylabel('Volts');title('Raw ECG Signal')
subplot(2,1,2)
plot(t(250:2250),x1(250:2250))
xlabel('second');ylabel('Volts');title('Input ECG Signal 1-9 second')
xlim([1 9])

%CANCELLATION DC DRIFT AND NORMALIZATION
x1 = x1 - mean (x1);    % cancel DC components
x1 = x1/ max( abs(x1 )); % normalize to one
figure(2)
plot(t,x1)
xlabel('second');ylabel('Volts');title('Cancellation DC Drift and Normalization')
%First, in order to attenuate noise, the signal passes through a
%digital bandpass filter composed of cascaded high-pass and lowpass filters.
%The bandpass filter, formed using lowpass and highpass filters, reduces noise in the ECG
%signal. Noise such as muscle noise, 60 Hz interference, and baseline drift are removed by bandpass
%filtering.

%LOW PASS FILTERING
% LPF (1-z^-6)^2/(1-z^-1)^2
figure(3)
subplot(3,1,1)
plot(t,x1)
xlabel('second');ylabel('Volts');title('Cancellation DC Drift and Normalization')
b=[1 0 0 0 0 0 -2 0 0 0 0 0 1];
a=[1 -2 1];
h_LP=filter(b,a,[1 zeros(1,12)]); % transfer function of LPF
x2 = conv (x1 ,h_LP);
x2 = x2/ max( abs(x2 )); % normalize , for convenience .
subplot(3,1,2)
plot([0:length(x2)-1]/fs,x2)
xlabel('second');ylabel('Volts');title('Passing through Lowpass Filter')

%HIGH PASS FILTERING
% HPF = Allpass-(Lowpass) = z^-16-[(1-z^-32)/(1-z^-1)]
b = [-1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 32 -32 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
a = [1 -1];
h_HP=filter(b,a,[1 zeros(1,32)]); % impulse response of HPF
x3 = conv (x2 ,h_HP);
x3 = x3/ max( abs(x3 ));
subplot(3,1,3)
plot([0:length(x3)-1]/fs,x3)
xlabel('second');ylabel('Volts');title('Passing through Highpass Filter')

%DERIVATIVE FILTER
% Make impulse response
h = [-1 -2 0 2 1]/8;
% Apply filter
x4 = conv (x3 ,h);
x4 = x4 (2+[1: N]);
x4 = x4/ max( abs(x4 ));
t4 = [0:length(x4)-1]/fs
figure(4)
subplot(2,1,1)
plot(t4(250:2250),x4(250:2250))
xlabel('second');ylabel('Volts');title('Passing through Derivative Filter 1-9 second')
xlim([1 9])
%SQUARING
x5 = x4 .^2;
x5 = x5/ max( abs(x5 ));
t5 = [0:length(x5)-1]/fs
subplot(2,1,2)
plot(t5(250:2250),x5(250:2250))
xlabel('second');ylabel('Volts');title('After Squaring 1-9 second')
xlim([1 9])
%MOVING WINDOW INTEGRATION
%
h = ones (1 ,31)/31;
% Apply filter
x6 = conv (x5 ,h);
x6 = x6 (15+[1: N]);
x6 = x6/ max( abs(x6 ));
figure(5)
plot([0:length(x6)-1]/fs,x6)
xlabel('second');ylabel('Volts');title('ECG Signal After Applying Pan Tomkins Algorithm')

%Finding the R in QRS
y=[0:length(x6)-1]/fs;
figure(8)

[pks,locs]=findpeaks(x6,'MinPeakDistance',100);
subplot(4,1,1)
plot([0:length(x6)-1]/fs,x6,y(locs),pks,'o','MarkerFaceColor','g','MarkerSize',5);
title('Plotting The R Peak by Using FINDPEAK Function (100 Minimum Amplitude Difference)')

[pks,locs]=findpeaks(x6,'MinPeakDistance',150);
subplot(4,1,2)
plot([0:length(x6)-1]/fs,x6,y(locs),pks,'o','MarkerFaceColor','g','MarkerSize',5);
title('Plotting The R Peak by Using FINDPEAK Function (150 Minimum Amplitude Difference)')

[pks,locs]=findpeaks(x6,'MinPeakDistance',200);
subplot(4,1,3)
plot([0:length(x6)-1]/fs,x6,y(locs),pks,'o','MarkerFaceColor','g','MarkerSize',5);
title('Plotting The R Peak by Using FINDPEAK Function (200 Minimum Amplitude Difference)')

[pks,locs]=findpeaks(x6,'MinPeakDistance',400);
subplot(4,1,4)
plot([0:length(x6)-1]/fs,x6,y(locs),pks,'o','MarkerFaceColor','g','MarkerSize',5);
title('Plotting The R Peak by Using FINDPEAK Function (400 Minimum Amplitude Difference)')









max_h = max(x6);
thresh = mean (x6 );
poss_reg =(x6>thresh*max_h)';

left = find(diff([0 poss_reg])==1);
right = find(diff([poss_reg 0])==-1);

left=left-(5+10);  % cancle delay because of LP and HP
right=right-(5+10);% cancle delay because of LP and HP

for i=1:length(left)
    [R_value(i) R_loc(i)] = max( x6(left(i):right(i)) );
    R_loc(i) = R_loc(i)-1+left(i); % add offset
end

% there is no selective wave
R_loc=R_loc(find(R_loc~=0));

[pmks,ilocs]=findpeaks(-x6+1,'MinPeakDistance',100);
hold on
figure(9);
subplot(2,1,2)
plot([0:length(x6)-1]/fs,x6,y(R_loc),R_value,'o','MarkerFaceColor','r','MarkerSize',5);
title('Plotting The R Peak by Using Threshold');
subplot(2,1,1)
[pks,locs]=findpeaks(x6,'MinPeakDistance',150);
plot([0:length(x6)-1]/fs,x6,y(locs),pks,'o','MarkerFaceColor','g','MarkerSize',5);
title('Plotting The R Peak by Using FINDPEAK Function (150 Minimum Amplitude Difference)')

figure(10)
plot([0:length(x6)-1]/fs,x6,y(ilocs),pmks-1,'o','MarkerFaceColor','g','MarkerSize',10);
title('Plotting the Q and S for Calculation of QRS Width');
%Calculating Heart Rate
%Heart Rate= (fs*60)/y;
nobh=length(pks);
tl=length(x6)/fs;
hr=(nobh*60)/tl;
disp('Heart Rate ');
fprintf('%d\n',round(hr))

%Calculating QRS Width
QrsWidth=mean(diff(ilocs));

disp('QRS Width in MiliSeconds');
fprintf('%d\n',round(QrsWidth))
