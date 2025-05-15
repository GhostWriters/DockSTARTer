# shellcheck shell=bash
# Dialog color codes to be used in the GUI menu

# shellcheck disable=SC2168 # local is only valid in functions
local \
    ColorHeading \
    ColorHeadingValue \
    ColorHighlight
# shellcheck disable=SC2034 # variable appears unused. Verify it or export it.
{
    ColorHeading='\Zr'
    ColorHeadingValue='\Zb\Zr'
    ColorHighlight='\Z3\Zb'
}

# shellcheck disable=SC2168 # local is only valid in functions
local \
    ColorHeadingLine \
    ColorCommentLine \
    ColorOtherLine \
    ColorVarLine \
    ColorAddVariableLine
# shellcheck disable=SC2034 # variable appears unused. Verify it or export it.
{
    ColorHeadingLine='\Zn'
    ColorCommentLine='\Z0\Zb\Zr'
    ColorOtherLine="${ColorCommentLine}"
    ColorVarLine='\Z0\ZB\Zr'
    ColorAddVariableLine="${ColorVarLine}"
}
