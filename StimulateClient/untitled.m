getDigit(12345, 3)

function digit = getDigit(num, n)
    digit = floor(mod(num, 10^n) / 10^(n-1));
end
