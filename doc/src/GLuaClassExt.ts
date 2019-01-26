
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
import { IGLuaList, DocumentationRoot } from './DocumentationRoot';

class GLuaClassExtension implements IGLuaList {
	entries = new Map<string, GLuaEntryBase>()
	description = '*No description avaliable*'

	constructor(public root: DocumentationRoot, public id: string, public name = id) {

	}

	getUpLink() {
		return `../home`
	}

	buildLevels(level = 1): string {
		return `[${this.id}](../../${this.id}):`
	}

	getDocLevel(): number {
		return 1
	}

	pathToRoot() {
		return '../'
	}

	generateFiles(outputDir: string) {
		const index = this.generateIndex()
		mkdir(outputDir)
		mkdir(outputDir + '/functions')
		mkdir(outputDir + '/variables')

		fs.writeFileSync(outputDir + '.md', index, {encoding: 'utf8'})

		for (const [name, entry] of this.entries) {
			if (entry instanceof GLuaFunction) {
				entry.generateFile(outputDir + '/functions/' + name + '.md')
			}
		}
	}

	generateFunctionList(prefix = '', namePrefix = '') {
		const output = []

		for (const [name, entry] of this.entries) {
			if (entry instanceof GLuaFunction) {
				output.push(`* [${namePrefix}${entry.name}](${prefix}./${this.id}/functions/${name})(${entry.args.buildMarkdown()})`)
			}
		}

		output.sort()

		return output
	}

	generateIndex() {
		const funcs = this.generateFunctionList()

		let prettyName = this.name

		if (this.root.panels.has(this.id)) {
			prettyName = `Panel: [${this.name}](../../panels/${this.id})`
		}

		return `## ${prettyName}
[Go up](../home)
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
