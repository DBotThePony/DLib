
-- Copyright (C) 2017-2020 DBotThePony

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.


-- You may, free of charge, download and use the SDK to develop a modified Valve game
-- running on the Source engine.  You may distribute your modified Valve game in source and
-- object code form, but only for free. Terms of use for Valve games are found in the Steam
-- Subscriber Agreement located here: http:--store.steampowered.com/subscriber_agreement/

--   You may copy, modify, and distribute the SDK and any modifications you make to the
-- SDK in source and object code form, but only for free.  Any distribution of this SDK must
-- include this LICENSE file and thirdpartylegalnotices.txt.

--   Any distribution of the SDK or a substantial portion of the SDK must include the above
-- copyright notice and the following:

--     DISCLAIMER OF WARRANTIES.  THE SOURCE SDK AND ANY
--     OTHER MATERIAL DOWNLOADED BY LICENSEE IS PROVIDED
--     "AS IS".  VALVE AND ITS SUPPLIERS DISCLAIM ALL
--     WARRANTIES WITH RESPECT TO THE SDK, EITHER EXPRESS
--     OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED
--     WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT,
--     TITLE AND FITNESS FOR A PARTICULAR PURPOSE.

--     LIMITATION OF LIABILITY.  IN NO EVENT SHALL VALVE OR
--     ITS SUPPLIERS BE LIABLE FOR ANY SPECIAL, INCIDENTAL,
--     INDIRECT, OR CONSEQUENTIAL DAMAGES WHATSOEVER
--     (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF
--     BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF
--     BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS)
--     ARISING OUT OF THE USE OF OR INABILITY TO USE THE
--     ENGINE AND/OR THE SDK, EVEN IF VALVE HAS BEEN
--     ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

PHYSGUN_MUST_BE_DETACHED = 0
PHYSGUN_IS_DETACHING = 1
PHYSGUN_CAN_BE_GRABBED = 2
PHYSGUN_ANIMATE_ON_PULL = 3
PHYSGUN_ANIMATE_IS_ANIMATING = 4
PHYSGUN_ANIMATE_FINISHED = 5
PHYSGUN_ANIMATE_IS_PRE_ANIMATING = 6
PHYSGUN_ANIMATE_IS_POST_ANIMATING = 7

-- settings for m_takedamage
DAMAGE_MODE_NO                              = 0
DAMAGE_MODE_GODMODE                         = 0
DAMAGE_MODE_EVENTS_ONLY                     = 1 -- Call damage functions, but don't modify health
DAMAGE_MODE_BUDDHA                          = 1  -- Call damage functions, but don't modify health
DAMAGE_MODE_YES                             = 2
DAMAGE_MODE_ENABLED                         = 2
DAMAGE_MODE_AIM                             = 3

_G.SNDLVL_NONE                              = 0
_G.SNDLVL_20dB                              = 20
_G.SNDLVL_25dB                              = 25
_G.SNDLVL_30dB                              = 30
_G.SNDLVL_35dB                              = 35
_G.SNDLVL_40dB                              = 40
_G.SNDLVL_45dB                              = 45
_G.SNDLVL_50dB                              = 50
_G.SNDLVL_55dB                              = 55
_G.SNDLVL_60dB                              = 60
_G.SNDLVL_IDLE                              = 60
_G.SNDLVL_65dB                              = 65
_G.SNDLVL_STATIC                            = 66
_G.SNDLVL_70dB                              = 70
_G.SNDLVL_75dB                              = 75
_G.SNDLVL_NORM                              = 75
_G.SNDLVL_80dB                              = 80
_G.SNDLVL_TALKING                           = 80
_G.SNDLVL_85dB                              = 85
_G.SNDLVL_90dB                              = 90
_G.SNDLVL_95dB                              = 95
_G.SNDLVL_100dB                             = 100
_G.SNDLVL_105dB                             = 105
_G.SNDLVL_110dB                             = 110
_G.SNDLVL_120dB                             = 120
_G.SNDLVL_130dB                             = 130
_G.SNDLVL_140dB                             = 140
_G.SNDLVL_GUNFIRE                           = 140
_G.SNDLVL_150dB                             = 150
_G.SNDLVL_180dB                             = 180
