
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
	default?: string
}

interface CommentaryReturn {
	type: string
	name?: string
	description?: string
}

class AnnotationCommentary {
	isFunction = false
	isEnum = false
	isType = false

	path: string | null = null
	aliases: string[] = []
	arguments: string | null = null
	returns: string[] = []
	returnsParsed: CommentaryReturn[] = []
	descriptionLines: string[] = []
	description = 'No description prodivded'

	library: string | string[] | null = null
	funcname: string | null = null

	argumentsParsed: CommentaryArgument[] = []

	constructor(public source: string, public text: string[]) {
		let description = false
		let returns = false

		for (const line of text) {
			const trim = line.trim()
			const lower = trim.toLowerCase()

			if (lower == '@enddesc' && description) {
				description = false
				continue
			}

			if (lower == '@endreturns' && returns) {
				returns = false
				continue
			}

			if (description) {
				this.descriptionLines.push(trim)
				continue
			}

			if (returns) {
				this.returns.push(trim)
				continue
			}

			if (lower == '') {
				continue
			}

			if (lower == '@doc') {
				continue
			}

			if (lower.startsWith('@fname')) {
				this.isFunction = true
				this.path = trim.substr(7).trim()
				continue
			}

			if (lower.startsWith('@path')) {
				this.isFunction = true
				this.path = trim.substr(6).trim()
				continue
			}

			if (lower.startsWith('@funcname')) {
				this.isFunction = true
				this.path = trim.substr(10).trim()
				continue
			}

			if (lower.startsWith('@alias')) {
				this.isFunction = true
				this.aliases.push(trim.substr(8).trim())
				continue
			}

			if (lower.startsWith('@args')) {
				this.isFunction = true
				this.arguments = trim.substr(6).trim()
				continue
			}

			if (lower == '@desc') {
				description = true
				continue
			}

			if (lower == '@returns') {
				returns = true
				continue
			} else if (lower.startsWith('@returns')) {
				this.returns.push(trim.substr(9).trim())
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
					const matchDefault = trim.match(/\S\s*\=\s*(\S+)$/)

					if (!matchDefault) {
						this.argumentsParsed.push({
							type: divide[0],
							name: divide[1]
						})
					} else {
						this.argumentsParsed.push({
							type: divide[0],
							name: divide[1],
							default: matchDefault[1]
						})
					}
				} else {
					console.error('Malformed argument string: ' + this.arguments)
					console.error('(missing argument name/type!)')
					console.warn('...in ' + source)
					console.warn()
				}
			}
		}

		{
			for (const line of this.returns) {
				const trim = line.trim()
				const divide = trim.split(':')

				if (divide[0] && divide[1]) {
					const name = divide[0].match(/\[([^]])+$\]/)

					if (name) {
						this.returnsParsed.push({
							'type': divide[0],
							'description': divide[1],
							'name': name[1]
						})
					} else {
						this.returnsParsed.push({
							'type': divide[0],
							'description': divide[1]
						})
					}
				} else {
					this.returnsParsed.push({
						type: divide[0]
					})
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
