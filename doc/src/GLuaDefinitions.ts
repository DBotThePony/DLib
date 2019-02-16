import { DocumentationRoot } from "./DocumentationRoot";

// Copyright (C) 2017-2019 DBot

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

class LuaArgument {
	num: number | null = null

	constructor(public type: string, public name?: string, public description?: string, public defaultValue?: string) {

	}

	get isGeneric() {
		return this.type == 'T'
	}

	get isBuiltIn() {
		return this.type == 'string'
			|| this.type == 'number'
			|| this.type == 'table'
			|| this.type == 'boolean'
			|| this.type == 'function'
			|| this.type == 'userdata'
			|| this.type == 'thread'
			|| this.type == 'vararg'
	}

	setNumber(num: number) {
		this.num = num
		return this
	}

	isDlibBased = false

	getLink() {
		switch (this.type) {
			case 'boolean':
				return 'http://www.lua.org/pil/2.2.html'
			case 'number':
				return 'http://www.lua.org/pil/2.3.html'
			case 'string':
				return 'http://www.lua.org/pil/2.4.html'
			case 'table':
				return 'http://www.lua.org/pil/2.5.html'
			case 'function':
				return 'http://www.lua.org/pil/2.6.html'
			case 'vararg':
				return 'http://www.lua.org/pil/5.2.html'
			case 'thread':
			case 'userdata':
				return 'http://www.lua.org/pil/2.7.html'
			case 'any':
				return 'http://wiki.garrysmod.com/page/Category:any'
			case 'T':
				return ''
		}

		if (this.isDlibBased) {
			// placeholder
			return `./types/${this.type}`
		}

		return `http://wiki.garrysmod.com/page/Global/${this.type}`
	}

	build() {
		if (!this.defaultValue)
			return `${this.type} ${this.name}`

		return `${this.type} ${this.name} = \`${this.defaultValue}\``
	}

	buildMarkdown() {
		if (this.isGeneric) {
			if (!this.defaultValue)
				return `T<?> (generic) ${this.name}`

			return `T<?> (generic) ${this.name} = \`${this.defaultValue}\``
		}

		if (!this.defaultValue)
			return `[${this.type}](${this.getLink()}) ${this.name}`

		return `[${this.type}](${this.getLink()}) ${this.name} = \`${this.defaultValue}\``
	}

	buildReturns(root: DocumentationRoot) {
		const description = this.description || '*-snip-*'

		if (this.name) {
			return `${this.num || ''} [${this.type}](${this.getLink()}): ${this.name}\x20\x20
${root.processLinks(description.replace(/^/, '\u200B\xA0\xA0\xA0\xA0\xA0\xA0\xA0\xA0'))}`
		} else {
			return `${this.num || ''} [${this.type}](${this.getLink()})\x20\x20
${root.processLinks(description.replace(/^/, '\u200B\xA0\xA0\xA0\xA0\xA0\xA0\xA0\xA0'))}`
		}
	}
}

class LuaArguments {
	args: LuaArgument[] = []

	constructor() {

	}

	get isEmpty() { return this.args.length == 0 }

	push(arg: LuaArgument) {
		this.args.push(arg)
		return this
	}

	pop(arg: LuaArgument) {
		return this.args.pop()
	}

	build() {
		const list = []

		for (const arg of this.args) {
			list.push(arg.build())
		}

		return list.join(', ')
	}

	buildMarkdown() {
		const list = []

		for (const arg of this.args) {
			list.push(arg.buildMarkdown())
		}

		return list.join(', ')
	}

	buildReturns(root: DocumentationRoot) {
		if (this.args.length == 0) {
			return `\u200B\xA0\xA0\xA0\xA0\xA0\xA0\xA0\xA0*void*`
		}

		const list = []

		for (const arg of this.args) {
			list.push(arg.buildReturns(root))
		}

		return list.join('\n\n')
	}
}

export {LuaArgument, LuaArguments}
