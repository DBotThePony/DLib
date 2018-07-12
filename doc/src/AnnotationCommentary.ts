
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

interface CommentaryArgument {
	type: string
	name: string
}

class AnnotationCommentary {
	isFunction = false
	isEnum = false
	isType = false

	path: string | null = null
	arguments: string | null = null
	descriptionLines: string[] = []
	description = 'No description prodivded'

	library: string | string[] | null = null
	funcname: string | null = null

	argumentsParsed: CommentaryArgument[] = []

	constructor(public source: string, public text: string[]) {
		let description = false

		for (const line of text) {
			const trim = line.trim()
			const lower = trim.toLowerCase()

			if (lower == '@enddescription') {
				description = false
				continue
			}

			if (description) {
				this.descriptionLines.push(trim)
				continue
			}

			if (lower == '') {
				continue
			}

			if (lower == '@documentation') {
				continue
			}

			if (lower.startsWith('@path')) {
				this.isFunction = true
				this.path = trim.substr(6).trim()
				continue
			}

			if (lower.startsWith('@arguments')) {
				this.isFunction = true
				this.arguments = trim.substr(11).trim()
				continue
			}

			if (lower == '@description') {
				description = true
				continue
			}

			console.warn('Undefined line type:')
			console.warn(line)
			console.warn('...in ' + source)
		}

		if (this.arguments) {
			const split = this.arguments.split(',')

			for (const line of split) {
				const trim = line.trim()
				const divide = trim.split(' ')

				if (divide[0] && divide[1]) {
					this.argumentsParsed.push({
						type: divide[0],
						name: divide[1]
					})
				} else {
					console.error('Malformed argument string: ' + this.arguments)
					console.warn('...in ' + source)
				}
			}
		}

		if (this.descriptionLines.length != 0) {
			this.description = this.descriptionLines.join('  \n')
		}

		if (this.path) {
			const split = this.path.split('.')

			if (split.length == 1) {
				this.funcname = this.path
			} else if (split.length == 2) {
				this.library = split[0]
				this.funcname = split[1]
			} else {
				this.funcname = split.pop()!
				this.library = split
			}
		}
	}
}

export {AnnotationCommentary}
