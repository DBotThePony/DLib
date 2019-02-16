import { DocumentationRoot } from "./DocumentationRoot";

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
	isDeprecated = false
	isInternal = false
	isInNameSpace = false
	isHook = false
	isPanel = false

	isShared = true
	isClientside = false
	isServerside = false
	replacesDefault = false

	parent = 'EditablePanel'
	protected currentLine: string | null = null

	path: string | null = null
	aliases: string[] = []
	arguments: string | null = null
	returns: string[] = []
	returnsParsed: CommentaryReturn[] = []
	descriptionLines: string[] = []
	description = '*Tumbleweed rolls*'

	library: string | string[] | null = null
	namespace: string | null = null
	funcname: string | null = null

	argumentsParsed: CommentaryArgument[] = []

	get strType() {
		return this.isFunction && 'function'
			|| this.isEnum && 'enum'
			|| this.isPanel && 'panel'
			|| this.isHook && 'hook'
			|| 'undefined'
	}

	protected typeToFunction() {
		if (this.isHook || this.isEnum || this.isPanel) {
			this.reportError('Switching from one type to another in single context.', 'This is not how it works.', this.strType)
		}

		this.isFunction = true
	}

	protected typeToEnum() {
		if (this.isHook || this.isFunction || this.isPanel) {
			this.reportError('Switching from one type to another in single context.', 'This is not how it works.', this.strType)
		}

		this.isEnum = true
	}

	protected typeToHook() {
		if (this.isFunction || this.isEnum || this.isPanel) {
			this.reportError('Switching from one type to another in single context.', 'This is not how it works.', this.strType)
		}

		this.isHook = true
	}

	protected typeToPanel() {
		if (this.isHook || this.isEnum || this.isFunction) {
			this.reportError('Switching from one type to another in single context.', 'This is not how it works.', this.strType)
		}

		this.isPanel = true
	}

	constructor(public source: string, public text: string[]) {
		let description = false
		let returns = false

		for (const line of text) {
			this.currentLine = line
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
				this.descriptionLines.push(line.replace(/^\s/, ''))
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

			if (lower == '@deprecated') {
				this.isDeprecated = true
				continue
			}

			if (lower == '@replaces') {
				this.replacesDefault = true
				continue
			}

			if (lower == '@internal') {
				this.isInternal = true
				continue
			}

			if (lower == '@client') {
				if (this.isServerside) {
					console.error('@client overlaps @server!')
					console.error('...in ' + source)
				}

				if (this.isClientside) {
					console.warn('Duplicated @client entry')
					console.warn('...in ' + source)
				}

				this.isClientside = true
				this.isShared = false
				continue
			}

			if (lower == '@server') {
				if (this.isClientside) {
					console.error('@server overlaps @client!')
					console.error('...in ' + source)
				}

				if (this.isServerside) {
					console.warn('Duplicated @server entry')
					console.warn('...in ' + source)
				}

				this.isServerside = true
				this.isShared = false
				continue
			}

			if (lower.startsWith('@fname')) {
				this.typeToFunction()
				this.path = trim.substr(7).trim()
				continue
			}

			if (lower.startsWith('@func')) {
				this.typeToFunction()
				this.path = trim.substr(6).trim()
				continue
			}

			if (lower.startsWith('@path')) {
				this.typeToFunction()
				this.path = trim.substr(6).trim()
				continue
			}

			if (lower.startsWith('@panel')) {
				this.typeToPanel()
				this.path = trim.substr(7).trim()
				continue
			}

			if (lower.startsWith('@parent')) {
				this.typeToPanel()
				this.parent = trim.substr(8).trim()
				continue
			}

			if (lower.startsWith('@hook')) {
				this.typeToHook()
				this.path = trim.substr(6).trim()
				continue
			}

			if (lower.startsWith('@funcname')) {
				this.typeToFunction()
				this.path = trim.substr(10).trim()
				continue
			}

			if (lower.startsWith('@alias')) {
				//this.typeToFunction()
				this.aliases.push(trim.substr(8).trim())
				continue
			}

			if (lower.startsWith('@args')) {
				//this.typeToFunction()

				if (this.isPanel) {
					this.reportError('Panel can not have arguments defined')
				}

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

			this.reportError('Undefined line type: ')
		}

		this.currentLine = null

		if (this.arguments) {
			const split = this.arguments.split(',')
			let openParenthesis = 0
			let currentString = ''

			for (const line of split) {
				for (let i = 0; i < line.length; i++) {
					if (line[i] == '(') {
						openParenthesis++
					}

					if (line[i] == ')') {
						openParenthesis--
					}
				}

				if (currentString == '') {
					currentString = line
				} else {
					currentString += ',' + line
				}

				if (openParenthesis != 0) {
					continue
				}

				const trim = currentString.trim()
				currentString = ''
				const divide = trim.match(/(\S+)\s+(\S+)$/)
				const matchDefault = trim.match(/(\S+)\s+(\S+)\s*\=\s*([\s\S]+)$/)

				if (matchDefault) {
					this.argumentsParsed.push({
						type: matchDefault[1],
						name: matchDefault[2],
						default: matchDefault[3]
					})
				} else if (divide) {
					this.argumentsParsed.push({
						type: divide[1],
						name: divide[2]
					})
				} else {
					this.reportError('Malformed argument string: ' + this.arguments, '(missing argument name/type!)')
				}
			}

			if (openParenthesis != 0) {
				this.reportError('Expected clsoed parethesis', this.arguments, 'Argument string is malformed!')
			}
		}

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

		if (this.descriptionLines.length != 0) {
			this.description = this.descriptionLines.join('  \n')
		}

		if (this.path) {
			const split = this.path.split('.')

			if (split.length == 1) {
				const split = this.path.split(':')

				if (split.length == 1) {
					this.funcname = this.path
				} else {
					if (split.length != 2) {
						this.reportError('Malformed function name: ' + this.path, '(invalid amount of dots!)')
					} else {
						this.isInNameSpace = true
						this.namespace = split[0]
						this.funcname = split[1]
					}
				}
			} else if (split.length == 2) {
				this.library = split[0]
				this.funcname = split[1]
			} else {
				this.funcname = split.pop()!
				this.library = split
			}
		}
	}

	protected reportError(...lines: string[]) {
		for (const line of lines) {
			console.error(line)
		}

		if (this.currentLine) {
			console.error(this.currentLine)
		}

		console.error('...in ' + this.source)
		console.error()
	}
}

export {AnnotationCommentary}
