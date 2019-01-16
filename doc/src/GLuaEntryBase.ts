
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

class GLuaEntryBase {
	library: GLuaLibrary | GLuaClassExtension | null = null
	notes: string[] = []
	warnings: string[] = []
	disclaimers: string[] = []

	deprecated = false
	avoid = false
	override = false
	buggy = false

	get isGlobal() { return this.library == null }

	constructor(public name: string, public id: string, public description = 'No description avaliable') {

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
