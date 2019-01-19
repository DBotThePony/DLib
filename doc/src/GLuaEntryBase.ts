
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

import { GLuaLibrary } from "./GLuaLibrary";
import fs = require('fs')
import { GLuaClassExtension } from "./GLuaClassExt";
import { AnnotationCommentary } from "./AnnotationCommentary";
import { DocumentationRoot, IGLuaList } from "./DocumentationRoot";

enum GLuaRealm {
	CLIENT, SERVER, SHARED
}

export {GLuaRealm}

class GLuaEntryBase {
	library: IGLuaList | null = null
	notes: string[] = []
	warnings: string[] = []
	disclaimers: string[] = []
	realm = GLuaRealm.SHARED

	deprecated = false
	internal = false
	avoid = false
	override = false
	buggy = false

	get isGlobal() { return this.library == null }

	constructor(public root: DocumentationRoot, public name: string, public id: string, public description = 'No description avaliable') {

	}

	generateDescription(prefix = '') {
		return this.root.processLinks(this.description, prefix)!
			.replace(/^/, '\u200B\xA0\xA0\xA0\xA0\xA0\xA0\xA0\xA0')
			.replace(/\n/g, '\n\u200B\xA0\xA0\xA0\xA0\xA0\xA0\xA0\xA0')
	}

	importFrom(annotation: AnnotationCommentary) {
		this.deprecated = annotation.isDeprecated
		this.internal = annotation.isInternal
		this.realm = annotation.isShared ? GLuaRealm.SHARED : annotation.isClientside ? GLuaRealm.CLIENT : GLuaRealm.SERVER
	}

	generateFile(outputFile: string) {
		const contents = this.generatePage()

		fs.writeFileSync(outputFile, contents, {encoding: 'utf8'})
	}

	generatePage(): string {
		throw new Error('Generate page method is not implemeneted!')
	}

	generateNotes() {
		const lines = []

		for (const warn of this.notes) {
			lines.push(`* **NOTE:** ${warn}`)
		}

		return lines.join('  \n')
	}

	generateWarnings() {
		const lines = []

		for (const warn of this.warnings) {
			lines.push(`* **WARNING:** ${warn}`)
		}

		return lines.join('  \n')
	}

	generateDisclaimers() {
		const lines = []

		for (const warn of this.disclaimers) {
			lines.push(`* **DISCLAIMER:** ${warn}`)
		}

		return lines.join('  \n')
	}

	generateDeprecated() {
		return this.deprecated && '\n**DEPRECATED: This funciton is either deprecated in DLib or GMod itself (if acceptable). Please avoid usage of this.**' || ''
	}

	generateInternal() {
		return this.internal && '\n**INTERNAL: This function/method/property exists\nYou may be able call or use it.\nBut you don\'t have to!\nno, really.**' || ''
	}

	generateRealm() {
		if (this.realm == GLuaRealm.SHARED) {
			return ''
		}

		if (this.realm == GLuaRealm.CLIENT) {
			return '\nThis function/method/property is available only on **CLIENT** realm!\n'
		}

		return '\nThis function/method/property is available only on **SERVER** realm!\n'
	}

	addNote(note: string) {
		this.notes.push(note)
		return this
	}

	addWarning(warning: string) {
		this.warnings.push(warning)
		return this
	}
}

export {GLuaEntryBase}
