
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
import { DocumentationRoot, IGLuaList } from './DocumentationRoot';

class GLuaLibrary implements IGLuaList {
	entries = new Map<string, GLuaEntryBase>()
	libraries = new Map<string, GLuaLibrary>()
	parent: GLuaLibrary | null = null
	description = '*No description avaliable*'

	constructor(public root: DocumentationRoot, public id: string, public name = id) {

	}

	getUpLink() {
		return `../${this.id}`
	}

	getParentLink() {
		if (this.parent == null) {
			return `../home`
		}

		return `../../${this.parent.id}`
	}

	buildLevels(level = 1): string {
		if (this.parent == null) {
			return `[${this.id}](${'../'.repeat(level)}${level == 0 ? '/' : ''}${this.name}).`
		}

		return this.parent.buildLevels(level + 2) + `[${this.id}](${'../'.repeat(level)}${level == 0 ? '/' : ''}${this.name}).`
	}

	getDocLevel(): number {
		if (this.parent == null) {
			return 1
		}

		return this.parent.getDocLevel() + 1
	}

	pathToRoot() {
		return '../'.repeat(this.getDocLevel())
	}

	getSubLibrary(name: string) {
		if (!this.libraries.has(name)) {
			const lib = new GLuaLibrary(this.root, name)
			this.libraries.set(name, lib)
			lib.parent = this
		}

		return this.libraries.get(name)!
	}

	generateFiles(outputDir: string) {
		const index = this.generateIndex()
		mkdir(outputDir)
		mkdir(outputDir + '/functions')
		mkdir(outputDir + '/sub')

		fs.writeFileSync(outputDir + '.md', index, {encoding: 'utf8'})

		for (const [name, library] of this.libraries) {
			library.generateFiles(outputDir + '/sub/' + name)
		}

		for (const [name, entry] of this.entries) {
			if (entry instanceof GLuaFunction) {
				entry.generateFile(outputDir + '/functions/' + name + '.md')
			}
		}
	}

	generateFunctionList(prefix = '', prefixName = '') {
		const output = []

		for (const [name, entry] of this.entries) {
			if (entry instanceof GLuaFunction) {
				output.push(`* [${prefixName}${entry.name}](${prefix}./${this.id}/functions/${name})(${entry.args.buildMarkdown()})`)
			}
		}

		output.sort()

		return output
	}

	generateFunctionListReplaces(prefix = '', prefixName = '') {
		const output = []

		for (const [name, entry] of this.entries) {
			if (entry instanceof GLuaFunction && entry.replacesDefault) {
				output.push(`* [${prefixName}${entry.name}](${prefix}./${this.id}/functions/${name})(${entry.args.buildMarkdown()})`)
			}
		}

		output.sort()

		return output
	}

	generateFunctionListRecursive(prefix = '', prefixName = '') {
		const output = this.generateFunctionList(prefix, prefixName)

		for (const lib of this.libraries.values()) {
			output.push(...lib.generateFunctionList(`${prefix}./${this.id}/sub/`, `${prefixName}${lib.name}.`))
		}

		return output
	}

	generateReplacesFunctionListRecursive(prefix = '', prefixName = '') {
		const output = this.generateFunctionListReplaces(prefix, prefixName)

		for (const lib of this.libraries.values()) {
			output.push(...lib.generateReplacesFunctionListRecursive(`${prefix}./${this.id}/sub/`, `${prefixName}${lib.name}.`))
		}

		return output
	}

	generateIndex() {
		const funcs = this.generateFunctionList()
		const sublibs = []

		for (const [name, library] of this.libraries) {
			sublibs.push(`* [${library.name}](./${this.id}/sub/${name})`)
		}

		return `## ${this.name}
[Go up](${this.getParentLink()})
### Sub-libraries
${sublibs.join('  \n')}
### Functions/Methods
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

export {GLuaLibrary}
