
// Copyright (C) 2017-2018 DBot

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
	constructor(public type: string, public name: string) {

	}

	get isBuiltIn() {
		return this.type == 'string'
			|| this.type == 'number'
			|| this.type == 'table'
			|| this.type == 'boolean'
			|| this.type == 'function'
			|| this.type == 'userdata'
			|| this.type == 'thread'
	}

	isDlibBased = false

	getLink() {
		if (this.isBuiltIn) {
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
				default:
					return 'http://www.lua.org/pil/2.7.html'
			}
		}

		if (this.isDlibBased) {
			// placeholder
			return `./types/${this.type}`
		}

		return `http://wiki.garrysmod.com/page/Global/${this.type}`
	}

	build() {
		return `${this.type} ${this.name}`
	}

	buildMarkdown() {
		return `[${this.type}](${this.getLink()}) ${this.name}`
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
}

export {LuaArgument, LuaArguments}
