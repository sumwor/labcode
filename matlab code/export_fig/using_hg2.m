%USING_HG2 Determine if the HG2 graphics pipeline is used
%
%   tf = using_hg2(fig)
%
%IN:
%   fig - handle to the figure in question.
%
%OUT:
%   tf - boolean indicating whether the HG2 graphics pipeline is being used
%        (true) or not (false).

function tf = using_hg2(fig)
if verLessThan('matlab','8.4.0') verLessThan('matlab','8.4.0')
    try
        tf = ~graphicsversion(fig, 'handlegraphics');
    catch
        tf = false;
    end
else
    tf=1;
end