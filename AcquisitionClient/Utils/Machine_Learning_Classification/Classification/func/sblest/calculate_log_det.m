function log_det_X = calculate_log_det(X)
    % This function calculates the log determinant of a matrix X
    % by normalizing its diagonal elements to avoid infinite values.
    n = size(X,1); % Get the size of matrix X
    c = 10^floor(log10(X(1,1))); % Extract the scaling factor c as a power of 10
    A = X / c; % Normalize the matrix by the scaling factor
    log_det_A = log(det(A)); % Compute the log determinant of the normalized matrix
    log_det_X = n*log(c) + log_det_A; % Combine the results to get the log determinant of the original matrix
end