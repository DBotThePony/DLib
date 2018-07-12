
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
import { LuaArguments } from "./GLuaDefinitions";

class GLuaFunction extends GLuaEntryBase {
	args = new LuaArguments()

	generatePage() {
		const deprecated = this.deprecated && '\n**DEPRECATED: This funciton is either deprecated in DLib or GMod itself (if acceptable). Do not use (really)**' || ''
		let levels = ''

		if (this.library) {
			levels = this.library.buildLevels()
		}

		return `# DLib documentation
## ${levels}${this.name}

### Usage:
${levels}${this.id}(${this.args.buildMarkdown()})

### Description
${this.description}
${deprecated}
---------------------
${this.generateNotes()}

${this.generateWarnings()}

${this.generateDisclaimers()}

[Go up](../index.md)`
	}
}

export {GLuaFunction}
