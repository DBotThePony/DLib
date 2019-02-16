
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

import { GLuaEntryBase } from "./GLuaEntryBase";
import { LuaArguments, LuaArgument } from "./GLuaDefinitions";
import { AnnotationCommentary } from "./AnnotationCommentary";

class GLuaFunction extends GLuaEntryBase {
	args = new LuaArguments()
	returns = new LuaArguments()

	importFrom(annotation: AnnotationCommentary) {
		super.importFrom(annotation)

		for (const arg of annotation.argumentsParsed) {
			this.args.push(new LuaArgument(arg.type, arg.name, undefined, arg.default))
		}

		let argnum = 0

		for (const arg of annotation.returnsParsed) {
			argnum++
			this.returns.push((new LuaArgument(arg.type, arg.name, arg.description)).setNumber(argnum))
		}
	}

	generateFullLink() {
		let levels = ''

		if (this.library) {
			levels = this.library.buildLevels(2)
		}

		return `${levels}[${this.name}](./functions/${this.name})`
	}

	generatePage() {
		let levels = ''

		if (this.library) {
			levels = this.library.buildLevels(2)
		}

		return `## ${levels}${this.name}

### Usage:

\u200B\xA0\xA0\xA0\xA0\xA0\xA0${levels}${this.id}(${this.args.buildMarkdown()})

${this.generateRealm()}

### Description

${this.generateDescription(this.library && this.library.pathToRoot() || '../')}

${this.generateDeprecated()}
${this.generateInternal()}
${this.generateReplaces()}

---------------------

### Returns

${this.returns.buildReturns(this.root)}

---------------------

${this.generateNotes()}

${this.generateWarnings()}

${this.generateDisclaimers()}

### [Go to upper level](${this.getUpLink()})`
	}
}

export {GLuaFunction}
