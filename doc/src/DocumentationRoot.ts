
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

import {GLuaLibrary} from './GLuaLibrary'
import {GLuaEntryBase} from './GLuaEntryBase'
import { AnnotationCommentary } from './AnnotationCommentary';
import { GLuaFunction } from './GLuaFunction';
import { LuaArgument } from './GLuaDefinitions';

import fs = require('fs')
import {mkdir} from './Util'

class DocumentationRoot {
	libraries = new Map<string, GLuaLibrary>()
	globals = new Map<string, GLuaEntryBase>()

	constructor() {

	}

	generateFiles(outputDir: string) {
		const index = this.generateIndex()
		mkdir(outputDir)
		mkdir(outputDir + '/sub')
		mkdir(outputDir + '/functions')

		fs.writeFileSync(outputDir + '/index.md', index, {encoding: 'utf8'})

		for (const [name, library] of this.libraries) {
			library.generateFiles(outputDir + '/sub/' + name)
		}

		for (const [name, globalvar] of this.globals) {
			if (globalvar instanceof GLuaFunction) {
				globalvar.generateFile(outputDir + '/functions/' + name + '.md')
			}
		}
	}

	generateIndex() {
		const libs = []
		const globals = []

		for (const [name, library] of this.libraries) {
			libs.push(`* [${library.name}](./sub/${name}/index.md)`)
		}

		for (const [name, globalvar] of this.globals) {
			if (globalvar instanceof GLuaFunction) {
				globals.push(`* Function: [${globalvar.name}](./functions/${name}.md)(${globalvar.args.buildMarkdown()})`)
			}
		}

		return `# DLib documentation
This small documentation fastly describes features (lol no, just points) of DLib library for GMod.

You can find many things outta here.
----------------------------
## Libraries
${libs.join('  \n')}
## Global Functions
${globals.join('  \n')}`
	}

	getLibrary(name: string) {
		if (!this.libraries.has(name)) {
			this.libraries.set(name, new GLuaLibrary(name))
		}

		return this.libraries.get(name)!
	}

	add(annotation: AnnotationCommentary) {
		if (annotation.isFunction) {
			const func = new GLuaFunction(annotation.funcname!, annotation.funcname!, annotation.description)

			for (const arg of annotation.argumentsParsed) {
				func.args.push(new LuaArgument(arg.type, arg.name, undefined, arg.default))
			}

			let argnum = 0

			for (const arg of annotation.returnsParsed) {
				argnum++
				func.returns.push((new LuaArgument(arg.type, arg.name, arg.description)).setNumber(argnum))
			}

			if (annotation.library == null) {
				this.globals.set(annotation.funcname!, func)
			} else if (typeof annotation.library == 'string') {
				this.getLibrary(annotation.library).add(func)
			} else {
				let library: GLuaLibrary

				for (const level of annotation.library) {
					if (library! == undefined) {
						library = this.getLibrary(level)
					} else {
						library = library!.getSubLibrary(level)
					}
				}

				library!.add(func)
			}
		}
	}
}

export {DocumentationRoot}
