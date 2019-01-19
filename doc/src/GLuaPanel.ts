
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

import { GLuaEntryBase } from "./GLuaEntryBase";
import { AnnotationCommentary } from "./AnnotationCommentary";

class GLuaPanel extends GLuaEntryBase {
	parent = 'EditablePanel'

	importFrom(annotation: AnnotationCommentary) {
		super.importFrom(annotation)

		this.parent = annotation.parent
	}

	generatePage() {
		let funcList = '*none*'

		if (this.root.classes.has(this.id)) {
			const classdef = this.root.classes.get(this.id)!
			funcList = classdef.generateFunctionList('../classes/' + this.id! + '/').join('\n')

			if (funcList == '') {
				funcList = '*none*'
			}
		}

		return `## Panel: ${this.name}
Parent: ${this.root.getPanelLink(this.parent)}

### Description

${this.generateDescription('../')}

${this.generateDeprecated()}
${this.generateInternal()}

---------------------

### Methods

${funcList}

---------------------

${this.generateNotes()}

${this.generateWarnings()}

${this.generateDisclaimers()}

### [Go to upper level](../home.md)`
	}
}

export {GLuaPanel}
