
-- Copyright (C) 2018 DBot

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

import VLL2, baseclass, table, string, assert, type from _G

VLL2.RecursiveMergeBase = (mergeMeta) ->
	return if not mergeMeta
	metaGet = baseclass.Get(mergeMeta)
	return if not metaGet.Base
	return if metaGet.Base == mergeMeta
	VLL2.RecursiveMergeBase(metaGet.Base)
	metaBase = baseclass.Get(metaGet.Base)
	metaGet[key] = value for key, value in pairs(metaBase) when metaGet[key] == nil

-- Easy to access functions
-- for those who want to use features without creating classes
VLL2.API = {
	LoadBundle: (bundleName, silent = false, replicate = true) ->
		assert(type(bundleName) == 'string', 'Bundle name must be a string')
		fbundle = VLL2.URLBundle(bundleName\lower())
		fbundle\Load()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadWorkshopContent: (wsid, silent = false, replicate = true) ->
		assert(type(wsid) == 'string', 'Bundle wsid must be a string')
		wsid = tostring(math.floor(assert(tonumber(wsid), 'Bundle wsid must represent a valid number within string!')))
		fbundle = VLL2.WSBundle(wsid)
		fbundle\Load()
		fbundle\DoNotLoadLua()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadWorkshopCollection: (wsid, silent = false, replicate = true) ->
		assert(type(wsid) == 'string', 'Bundle wsid must be a string')
		wsid = tostring(math.floor(assert(tonumber(wsid), 'Bundle wsid must represent a valid number within string!')))
		fbundle = VLL2.WSCollection(wsid)
		fbundle\Load()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadWorkshopCollectionContent: (wsid, silent = false, replicate = true) ->
		assert(type(wsid) == 'string', 'Bundle wsid must be a string')
		wsid = tostring(math.floor(assert(tonumber(wsid), 'Bundle wsid must represent a valid number within string!')))
		fbundle = VLL2.WSCollection(wsid)
		fbundle\Load()
		fbundle\DoNotLoadLua()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadWorkshop: (wsid, silent = false, replicate = true) ->
		assert(type(wsid) == 'string', 'Bundle wsid must be a string')
		wsid = tostring(math.floor(assert(tonumber(wsid), 'Bundle wsid must represent a valid number within string!')))
		fbundle = VLL2.WSBundle(wsid)
		fbundle\Load()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle
}
