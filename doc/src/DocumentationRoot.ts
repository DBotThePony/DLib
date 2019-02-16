
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

import {GLuaLibrary} from './GLuaLibrary'
import {GLuaEntryBase, GLuaRealm} from './GLuaEntryBase'
import { AnnotationCommentary } from './AnnotationCommentary';
import { GLuaFunction } from './GLuaFunction';
import { LuaArgument } from './GLuaDefinitions';

import fs = require('fs')
import {mkdir} from './Util'
import { GLuaClassExtension } from './GLuaClassExt';
import { GLuaPanel } from './GLuaPanel';
import { GLuaHook } from './GLuaHook';

interface IGLuaList {
	generateFunctionList(linkprefix?: string): string[]
	getDocLevel(): number
	pathToRoot(): string
	generateFiles(outputDir: string): void
	buildLevels(level?: number): string
	getUpLink(): string
	root: DocumentationRoot
}

export {IGLuaList}

class DocumentationRoot {
	libraries = new Map<string, GLuaLibrary>()
	panels = new Map<string, GLuaPanel>()
	classes = new Map<string, GLuaClassExtension>()
	globals = new Map<string, GLuaEntryBase>()
	hooks = new Map<string, GLuaHook>()

	getPanelLink(panelID: string, linkPrefix = '') {
		if (this.panels.has(panelID)) {
			return `[${panelID}](${linkPrefix}./panels/${panelID}.md)`
		} else {
			return `[${panelID}](http://wiki.garrysmod.com/page/Category:${panelID})`
		}
	}

	getClassLink(classname: string, linkPrefix = '') {
		if (this.classes.has(classname)) {
			return `[${classname}](${linkPrefix}./classes/${classname}.md)`
		} else {
			return `[${classname}](http://wiki.garrysmod.com/page/Category:${classname})`
		}
	}

	processLinks(description?: string, linkPrefix = '') {
		if (!description) {
			return description
		}

		return description.replace(/\!(g|p|c|s):(\S+)/g, (substr, arg1, arg2) => {
			switch (arg1) {
				case 'g':
					return `[${arg2}](http://wiki.garrysmod.com/page/${arg2.replace(/\.|:/g, '/')})`
				case 's':
					return `[${arg2}](http://wiki.garrysmod.com/Structures/${arg2.replace(/\.|:/g, '/')})`
				case 'p':
					return this.getPanelLink(arg2, linkPrefix)
				case 'c':
					return this.getClassLink(arg2, linkPrefix)
			}

			return substr
		})
	}

	generateFiles(outputDir: string) {
		mkdir(outputDir)
		mkdir(outputDir + '/sub')
		mkdir(outputDir + '/classes')
		mkdir(outputDir + '/functions')
		mkdir(outputDir + '/hooks')
		mkdir(outputDir + '/panels')

		fs.writeFileSync(outputDir + '/home.md', this.generateIndex(), {encoding: 'utf8'})
		fs.writeFileSync(outputDir + '/functions.md', this.generateFunctionsIndex(), {encoding: 'utf8'})
		fs.writeFileSync(outputDir + '/replaces.md', this.generateReplacementsIndex(), {encoding: 'utf8'})

		for (const [name, library] of this.libraries) {
			library.generateFiles(outputDir + '/sub/' + name)
		}

		for (const [name, classext] of this.classes) {
			classext.generateFiles(outputDir + '/classes/' + name)
		}

		for (const [name, hook] of this.hooks) {
			hook.generateFile(outputDir + '/hooks/' + name + '.md')
		}

		for (const [name, panel] of this.panels) {
			panel.generateFile(outputDir + '/panels/' + name + '.md')
		}

		for (const [name, globalvar] of this.globals) {
			if (globalvar instanceof GLuaFunction) {
				globalvar.generateFile(outputDir + '/functions/' + name + '.md')
			}
		}
	}

	generateFunctionsIndex() {
		const output = []

		for (const [name, globalvar] of this.globals) {
			if (globalvar instanceof GLuaFunction) {
				output.push(`* [${globalvar.name}](./functions/${name})(${globalvar.args.buildMarkdown()})`)
			}
		}

		for (const lib of this.libraries.values()) {
			output.push(...lib.generateFunctionListRecursive('./sub/', `${lib.name}.`))
		}

		for (const eclass of this.classes.values()) {
			output.push(...eclass.generateFunctionList(`./classes/`, `${eclass.name}:`))
		}

		output.sort()

		return `# Full function list
${output.join('  \n')}
`
	}

	generateReplacementsIndex() {
		const output = []

		for (const [name, globalvar] of this.globals) {
			if (globalvar instanceof GLuaFunction && globalvar.replacesDefault) {
				output.push(`* ${globalvar.generateFullLink()}(${globalvar.args.buildMarkdown()})`)
			}
		}

		for (const lib of this.libraries.values()) {
			output.push(...lib.generateReplacesFunctionListRecursive('./sub/', `${lib.name}.`))
		}

		output.sort()

		return `# Full list of functions which replace default ones
**This list does not include any implicit replacements caused by these replacements.**

${output.join('  \n')}
`
	}

	generateIndex() {
		const libs = []
		const classes = []
		const globals = []
		const panels = []

		for (const [name, library] of this.libraries) {
			libs.push(`* [${library.name}](./sub/${name})`)
		}

		for (const [name, classext] of this.classes) {
			classes.push(`* [${classext.name}](./classes/${name})`)
		}

		for (const [name, panel] of this.panels) {
			panels.push(`* [${panel.name}](./panels/${name})`)
		}

		for (const [name, globalvar] of this.globals) {
			if (globalvar instanceof GLuaFunction) {
				globals.push(`* Function: [${globalvar.name}](./functions/${name})(${globalvar.args.buildMarkdown()})`)
			}
		}

		return `This small documentation fastly describes features (lol no, just points) of DLib library for GMod.

You can find many things outta here.
----------------------------
[List of every function present inside libraries](./functions)

[List of functions which replace vanilla ones](./replaces)
## Libraries
${libs.join('  \n')}
## Class extensions
${classes.join('  \n')}
## Global Functions
${globals.join('  \n')}
## Panels
${panels.join('  \n')}
`
	}

	getLibrary(name: string) {
		if (!this.libraries.has(name)) {
			this.libraries.set(name, new GLuaLibrary(this, name))
		}

		return this.libraries.get(name)!
	}

	getClassExt(name: string) {
		if (!this.classes.has(name)) {
			this.classes.set(name, new GLuaClassExtension(this, name))
		}

		return this.classes.get(name)!
	}

	add(annotation: AnnotationCommentary) {
		if (annotation.isFunction) {
			const func = new GLuaFunction(this, annotation.funcname!, annotation.funcname!, annotation.description)
			func.importFrom(annotation)

			if (annotation.namespace != null) {
				this.getClassExt(annotation.namespace).add(func)
			} else if (annotation.library == null) {
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
		} else if (annotation.isPanel) {
			const panel = new GLuaPanel(this, annotation.path!, annotation.path!, annotation.description)
			panel.importFrom(annotation)

			this.panels.set(panel.id, panel)
		} else if (annotation.isHook) {
			const hook = new GLuaHook(this, annotation.path!, annotation.path!, annotation.description)
			hook.importFrom(annotation)

			this.hooks.set(hook.id, hook)
		}
	}
}

export {DocumentationRoot}
