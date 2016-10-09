img = imread('test.bmp');
img = 1 - img;
bw = im2bw(img,0.5);
[m,n] = size(bw);
addcol = false(m,1);
if sum(bw(:,n)) ~= 0
    bw = [bw,addcol];
end
tic;
[m,n] = size(bw);
n2 = uint16(n/2); %each row can have at most n/2 run-length
R = zeros(m, n2, 3); %run-length
R(:,:,3) = intmax; %set numRoot of run-length to max 
rootTable = zeros(4096,1); %equivalence table, max 65535
infoTable = zeros(m,1); %store if a row has run-length and the no. of run-length
temp_arr = zeros(n2,1); %temporary matrix for equivalence-solving in each row
numRoot = 0; %total number of target
numConflict = 0; %total number of conflicts

%%%%process the first row separately%%%%
x1 = false; %previous pixel
%f = false; %foreground
b = false; %start/end of a run-length
for j = 1:n
    x0 = bw(1,j);
    %f = bitxor(x0,x1);
    if x0 ~= x1
        if b == false
            numRoot = numRoot + 1;
            R(1,numRoot,1) = j;
        else
            R(1,numRoot,2) = j - 1;
            R(1,numRoot,3) = numRoot;
            rootTable(numRoot) = numRoot;
        end
        %b = bitxor(b,true);
        b = ~b;
    end
    x1 = x0;
end
infoTable(1) = numRoot;

%%%%start process and calculate from the second row%%%%
for i = 2:m
    x1 = false;
    %f = false;
    b = false;
    er = 0;
    for j = 1:n
        x0 = bw(i,j);
        %f = bitxor(x0,x1);
        if x0 ~= x1
            if ~b
                er = er + 1;
                R(i,er,1) = j;
            else
                R(i,er,2) = j - 1;
                numRLC1 = infoTable(i-1);
                if (numRLC1 ~= 0)
                    z_diff = 0; %no of matched target in previous row
                    for k = 1:numRLC1
                        if (R(i-1,k,1) <= (R(i,er,2)+1)) && (R(i-1,k,2) >= (R(i,er,1)-1))
                            z_diff = z_diff + 1;
                            temp_arr(z_diff) = R(i-1,k,3);
                            if temp_arr(z_diff) <= R(i,er,3)
                                R(i,er,3) = temp_arr(z_diff);
                            end
                        end
                    end
                    if z_diff == 0
                        numRoot = numRoot + 1;
                        R(i,er,3) = numRoot;
                        rootTable(numRoot) = numRoot;
                    elseif z_diff > 1
                        for x = 1:z_diff
                            if rootTable(temp_arr(x)) > R(i,er,3)
                                rootTable(temp_arr(x)) = R(i,er,3);
                            end
                        end                   
                    end
                else
                    numRoot = numRoot + 1;
                    R(i,er,3) = numRoot;
                    rootTable(numRoot) = numRoot;
                end
            end
            b = ~b; %b = bitxor(b,true);
        end
        x1 = x0;
    end
    infoTable(i) = er;
end
realRoot = 0;
for x=1:numRoot
    if rootTable(x) == x
        realRoot = realRoot + 1;
    end
end
fprintf('%d\n',realRoot);
toc;