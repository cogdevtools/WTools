% Define the parameters for the Morlet wavelets
s = 2; % Scale parameter
w = linspace(1, 150, 150); % Angular frequency parameter (100 frequencies)

% Define the range of x and t values
x = linspace(-10, 10, 50);
t = linspace(-1.5, 1.5, 3000);

% Create a grid of x and t values
[X, T] = meshgrid(x, t);

% Initialize a matrix to store the wavelet values
W = zeros(size(X));

% Compute the Morlet wavelet values for each frequency
for i = 1:numel(w)
    r = exp(-(X.^2 + (s*w(i)*T).^2)/2) .* cos(w(i)*X);
    W = W + r;
end

% Generate the 3D plot with colorization
figure;
colormap HSV; % Set colormap to hotter colors
h = surf(X, T, fliplr(W));
set(h,'LineStyle',':')
% xlabel('x');
% ylabel('t');
% zlabel('Morlet Wavelet');
% title('3D Morlet Wavelets at 100 Frequencies');
axis off; % Remove the axis
colorbar off; % Remove the colorbar
set(gcf,'Color','k');

% Save the 3D plot image without the axis and scale
saveas(gcf, '3DMorletWavelet.png');