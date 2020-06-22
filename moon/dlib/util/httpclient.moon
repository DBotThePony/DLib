
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

class http.DLibCookie
	@Parse = (strInput, domain, unsafe = false) =>
		assert(isstring(strInput), 'Input must be a string')
		split = strInput\split(';')
		_name = table.remove(split, 1)
		startPos, endPos = _name\find('=', 1, true)

		error('Malformed input. First key=value pair in cookie must always be cookie\'s name and value!') if not startPos
		cname = _name\sub(1, startPos - 1)
		cvalue = _name\sub(startPos + 1)
		data = {unsafedomain: true}

		for param in *split
			trim = param\trim()

			switch trim\lower()
				when 'secure'
					data.secure = true
				when 'httponly'
					data.httponly = true
				when 'unsafedomain'
					data.unsafedomain = true if unsafe
				else
					startPos, endPos = trim\find('=', 1, true)

					if startPos
						name = trim\sub(1, startPos - 1)
						value = trim\sub(startPos + 1)

						if name\lower() == 'max-age'
							if num = tonumber(value)
								data.override_expires = true

								if num == 0
									data.expires = nil
									data.session = true
								else
									data.expires = os.time() + num
									data.session = false
						elseif name\lower() == 'expires' and not data.override_expires
							data.expires = http.ParseDate(value)
							data.session = false

							if data.expires < 10
								data.expires = nil
								data.session = true
						elseif unsafe and name\lower() == 'created'
							data.created = http.ParseDate(value)
						elseif name\lower() == 'domain'
							data.domain = value
							data.unsafedomain = false
						elseif name\lower() == 'path'
							data.path = value

		cookie = @(cname, cvalue, data.domain or domain, data.path)

		cookie\SetIsSecure(true) if data.secure
		cookie\SetHttpOnly(true) if data.httponly
		cookie\SetCreationStamp(data.created) if data.created
		cookie\SetDomain(data.domain) if data.domain

		cookie\SetExplicitDomain(data.unsafedomain)

		if data.expires
			cookie\SetExpiresStamp(data.expires)
			cookie\SetIsSession(data.session)

		return cookie

	AccessorFunc(@__base, 'm_HttpOnly', 'HttpOnly', FORCE_BOOL)
	AccessorFunc(@__base, 'explicitDomain', 'ExplicitDomain', FORCE_BOOL)
	AccessorFunc(@__base, 'm_Session', 'IsSession', FORCE_BOOL)
	AccessorFunc(@__base, 'm_CreationTime', 'CreationStamp', FORCE_NUMBER)
	AccessorFunc(@__base, 'm_Expires', 'ExpiresStamp', FORCE_NUMBER)
	AccessorFunc(@__base, 'm_Secure', 'IsSecure', FORCE_BOOL)
	AccessorFunc(@__base, 'm_Path', 'Path', FORCE_STRING)
	AccessorFunc(@__base, 'm_Domain', 'Domain', FORCE_STRING)
	AccessorFunc(@__base, 'value', 'Value', FORCE_STRING)

	new: (name, value, domain, path = '/', explicitDomain = true) =>
		assert(isstring(name), 'Name must be a string')
		assert(isstring(value), 'Value must be a string')
		assert(not name\find(' ', 1, true) and not name\find('=', 1, true) and not name\find(';', 1, true) and not name\find('\n', 1, true), 'Cookie name can not contain special symbols')
		assert(not value\find(' ', 1, true) and not value\find('=', 1, true) and not value\find(';', 1, true) and not value\find('\n', 1, true), 'Cookie value can not contain special symbols')

		assert(isstring(domain), 'Domain must be a string')
		assert(isstring(path), 'Path must be a string')
		assert(isstring(domain), 'Domain must be a string')
		@name = name
		@value = value
		@m_HttpOnly = false
		@m_Domain = domain
		@m_Path = path
		@m_Secure = false
		@m_CreationTime = os.time()
		@m_Expires = math.huge
		@m_Session = true
		@explicitDomain = explicitDomain

	Expired: (stamp = os.time()) =>
		return false if @m_Session
		return @m_Expires < stamp

	Is: (path) =>
		return false if @Secure and not path\startsWith('https://')
		protocol, domain = path\match('(https?)://([a-zA-Z0-9.-]+)')
		return false if not protocol or not domain
		return false if @explicitDomain and @m_Domain ~= domain
		return false if not @explicitDomain and not domain\endsWith(@m_Domain)
		uripath = path\sub(#protocol + 4 + #domain)\trim()
		uripath = '/' if uripath == ''
		return uripath\startsWith(@m_Path)

	-- slightly inaccurate - insecure cookies == insecure cookies, but
	-- secure cookies != insecure cookies
	Hash: => "#{@name}_#{@m_Domain}[#{@explicitDomain}]_#{util.CRC(@m_Path)}_#{@m_Secure}"
	Value: => "#{@name}=#{@value}"

	Serialize: =>
		build = {
			@name .. '=' .. @value
			'Created=' .. os.date('%a, %d %b %Y %H:%M:%S GMT', @m_CreationTime)
			'Domain=' .. @m_Domain
			'Path=' .. @m_Path
		}

		table.insert(build, 'HttpOnly') if @m_HttpOnly
		table.insert(build, 'Expires=' .. os.date('%a, %d %b %Y %H:%M:%S GMT', @m_Expires)) if not @m_Session
		table.insert(build, 'UnsafeDomain') if @explicitDomain

		return table.concat(build, '; ')

class http.DLibCookieJar
	new: =>
		@jar = {}

	Add: (input, domain) =>
		cookie = isstring(input) and http.DLibCookie\Parse(input, domain) or input
		hash = cookie\Hash()

		if @jar[hash]
			cookie\SetCreationStamp(@jar[hash]\GetCreationStamp())

		@jar[hash] = cookie
		return @

	Remove: (input, domain) =>
		cookie = isstring(input) and http.DLibCookie\Parse(input, domain) or input
		hash = cookie\Hash()

		if @jar[hash]
			@jar[hash] = nil
			return true

		return false

	GetFor: (url) =>
		for hash, cookie in pairs(@jar)
			if cookie\Expired()
				@jar[hash] = nil

		return [cookie for hash, cookie in pairs(@jar) when cookie\Is(url)]

import Promise from DLib

class http.DLibClient
	AccessorFunc(@__base, 'set_referer', 'SetReferer', FORCE_BOOL)
	AccessorFunc(@__base, 'last_referer', 'LastReferer')

	new: (cookiejar) =>
		if isstring(cookiejar)
			error('serializing of cookiejar is not supported yet')
		elseif type(cookiejar) == 'table'
			@cookiejar = cookiejar
		else
			@cookiejar = http.DLibCookie()

		@set_referer = true
		@last_referer = false

	CookieList: (url) =>
		cookies = @cookiejar\GetFor(url)
		return false if not cookies or #cookies == 0
		return table.concat([cookie\Value() for cookie in *cookies], '; ')

	Patch: (url, headers) =>
		cookieList = @CookieList(url)

		hit = not cookieList
		hit2 = not @last_referer
		return headers if hit and hit2

		for headerName in pairs(headers)
			hit = true if not hit and headerName\lower() == 'cookie'
			hit2 = true if not hit2 and headerName\lower() == 'referer'

		headers.Cookie = cookieList if not hit
		headers.Referer = @last_referer if not hit2
		return headers

	_Domain: (url) => url\match('https?://([a-zA-Z0-9.-]+)')\lower()
	_Receive: (domain, headers) =>
		for key, value in pairs(headers)
			if key\lower() == 'set-cookie'
				@cookiejar\Add(value, domain)

	Get: (url, headers = {}) =>
		Promise (resolve, reject) ->
			http.PromiseGet(url, @Patch(url, headers))\Catch(reject)\Then (body = '', size = 0, headers = {}, code = 500, ...) ->
				@_Receive(@_Domain(url), headers)
				@last_referer = url if code >= 200 and code < 300
				resolve(body, size, headers, code, ...)

	Post: (url, params, headers = {}) =>
		Promise (resolve, reject) ->
			http.PromisePost(url, params, @Patch(url, headers))\Catch(reject)\Then (body = '', size = 0, headers = {}, code = 500, ...) ->
				@_Receive(@_Domain(url), headers)
				@last_referer = url if code >= 200 and code < 300
				resolve(body, size, headers, code, ...)

	PostBody: (url, body, headers = {}) =>
		Promise (resolve, reject) ->
			http.PromisePostBody(url, body, @Patch(url, headers))\Catch(reject)\Then (body = '', size = 0, headers = {}, code = 500, ...) ->
				@_Receive(@_Domain(url), headers)
				@last_referer = url if code >= 200 and code < 300
				resolve(body, size, headers, code, ...)

	Put: (url, body, headers = {}) =>
		Promise (resolve, reject) ->
			http.PromisePut(url, body, @Patch(url, headers))\Catch(reject)\Then (body = '', size = 0, headers = {}, code = 500, ...) ->
				@_Receive(@_Domain(url), headers)
				@last_referer = url if code >= 200 and code < 300
				resolve(body, size, headers, code, ...)

	Head: (url, headers = {}) =>
		Promise (resolve, reject) ->
			http.PromiseHead(url, @Patch(url, headers))\Catch(reject)\Then (headers = {}, code = 500, ...) ->
				@_Receive(@_Domain(url), headers)
				@last_referer = url if code >= 200 and code < 300
				resolve(headers, code, ...)
