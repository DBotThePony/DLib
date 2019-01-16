
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

import { GLuaEntryBase } from './GLuaEntryBase';
import {mkdir} from './Util'

import fs = require('fs')
import { GLuaFunction } from './GLuaFunction';

class GLuaClassExtension {
	entries = new Map<string, GLuaEntryBase>()
	description = '*No description avaliable*'

	constructor(public id: string, public name = id) {

	}

	buildLevels(level = 1): string {
		return `[${this.id}](../index.md):`
	}

	generateFiles(outputDir: string) {
		const index = this.generateIndex()
		mkdir(outputDir)
		mkdir(outputDir + '/functions')
		mkdir(outputDir + '/variables')

		fs.writeFileSync(outputDir + '/index.md', index, {encoding: 'utf8'})

		for (const [name, entry] of this.entries) {
			if (entry instanceof GLuaFunction) {
				entry.generateFile(outputDir + '/functions/' + name + '.md')
			}
		}
	}

	generateIndex() {
		const funcs = []

		for (const [name, entry] of this.entries) {
			if (entry instanceof GLuaFunction) {
				funcs.push(`* [${entry.name}](./functions/${name}.md)(${entry.args.buildMarkdown()})`)
			}
		}

		return `# DLib documentation
## ${this.name}
[../index.md](Go up)
### Methods
${funcs.join('  \n')}`
	}

	add(entry: GLuaEntryBase) {
		if (entry.library != null) {
			throw new Error('Function is already present in library! ' + entry.id)
		}

		this.entries.set(entry.id, entry)
		entry.library = this
	}
}

export {GLuaClassExtension}
