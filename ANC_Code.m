clear;
[mic1,fs1]=audioread('Corrupted_Speech.wav'); % Reading first input file
[mic2,fs2]=audioread('White_Noise.wav'); % Reading second input file
[clean,fs3]=audioread('cleanspeech.wav'); % Reading cleanspeech input file

N=256; % Specify window size
mu=0.003; % Parameter to adapt the coefficients of the filter
K= fix(min(length(mic1),length(mic2))/N); % Computing the number of frames
B_initial=zeros(N,1); % Initial frequency response of filter

E2=zeros(length(clean),1); % Fixing length of reduced noise signal same as 'cleanspeech' signal
e2=zeros(length(clean),1); % Fixing length of reduced noise signal same as 'cleanspeech' signal
for k = 1:K
    % Compute indices for current frame
    j = (1:N)+(N*(k-1));
    D=fft(mic1(j),N); % N point FFT of mic1 input
    X=fft(mic2(j),N); % N point FFT of mic2 input
    X_diag=diag(X);
   
    if k==1
        E(1:N,k)= D- X_diag*B_initial; % Frequency domain signal of speech with reduced noise stored frame by frame
        e(1:N,k)=ifft(E(1:N,k)); % Time domain signal of speech with reduced noise stored frame by frame
        
        % We now again calculate reduced noise speech signal as a single vector
        % as that would help with the SNR calculation
    
        E2(j,1)= D- X_diag*B_initial; % Frequency domain signal of speech with reduced noise stored as a vector
        e2(j,1)=ifft(E2(j,1)); % Time domain signal of speech with reduced noise stored as a vector
        B(:,k)= B_initial+2*mu*X_diag'*E(1:N,k);
    else
        E(1:N,k)= D- X_diag*B(:,k-1);
        e(1:N,k)=ifft(E(1:N,k));
    
        E2(j,1)= D- X_diag*B(:,k-1);
        e2(j,1)=ifft(E2(j,1));
        B(:,k)= B(:,k-1) +2*mu*X_diag'*E(1:N,k); % Storing the frequency response of the filter
    end  
end

SNR_before= 10*log10((clean'*clean)/((clean-mic1)'*(clean-mic1))); % SNR before filtering
SNR_after=10*log10((clean'*clean)/((clean-e2)'*(clean-e2))); % SNR after filtering

N % Filter size
mu % Step size
SNR_change=SNR_after-SNR_before % SNR improvement

for p=1:K
    energy(1,p)=10*log10(E(:,p)'*E(:,p)); % Calculating energy of each frame to find energy convergence
end

figure;
plot(energy) % Plotting energy against the frame number
msg=sprintf('Convergence curve for N=%d, Mu=%f', N, mu);
title(msg);
xlabel('Frame number');
ylabel('Energy (dB)');

audiowrite('Filtered_Speech.wav',e2,fs1)

playstate=input('Press 1 if you want to hear the filtered speech. Else press 0 -> ');

if playstate==1
sound(e2,fs1)
end