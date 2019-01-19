
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

import { GLuaFunction } from "./GLuaFunction";

class GLuaHook extends GLuaFunction {
	generatePage() {
		let levels = ''

		if (this.library) {
			levels = this.library.buildLevels()
		}

		return `## ${this.name} hook

### Hook defintion:

\u200B\xA0\xA0\xA0\xA0\xA0\xA0\`${this.id}\`(${this.args.buildMarkdown()})

${this.generateRealm()}

### Description

${this.generateDescription('../')}

${this.generateDeprecated()}
${this.generateInternal()}

---------------------

### This hook returns (if any)

${this.returns.buildReturns(this.root)}

---------------------

${this.generateNotes()}

${this.generateWarnings()}

${this.generateDisclaimers()}

### [Go to upper level](../index.md)`
	}
}

export {GLuaHook}
