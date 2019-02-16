
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

import {AnnotationCommentary} from './src/AnnotationCommentary'

const filesToParse: string[] = []

import fs = require('fs')
import { DocumentationRoot } from './src/DocumentationRoot';

const findFiles = (dir: string) => {
	const list = fs.readdirSync(dir)

	for (const file of list) {
		const stat = fs.statSync(dir + '/' + file)

		if (stat.isDirectory()) {
			findFiles(dir + '/' + file)
		} else if (file.match(/\.lua$/)) {
			filesToParse.push(dir + '/' + file)
		}
	}
}

findFiles('../lua_src')

if (filesToParse.length == 0) {
	console.log('Nothing to parse!')
	process.exit(0)
}

const findCommentaries = /--\[\[([\s\S]+?)\]\]/gm
const annotations = []

for (const file of filesToParse) {
	const read = fs.readFileSync(file, {encoding: 'utf8'})
	const match = read.match(findCommentaries)

	if (match) {
		//console.log(match)

		for (const commentary of match) {
			let bad = false
			const lines = commentary.split(/\r?\n/)
			let pos = 0

			for (const line of lines) {
				pos++
				const trim = line.trim()

				if (trim.match(/[a-z]/i) && trim.toLowerCase() != '@doc' && trim.toLowerCase() != '@docpreprocess') {
					bad = true
					break
				}

				if (trim.toLowerCase() == '@docpreprocess') {
					bad = true
					const linesEval = []

					for (let i = pos; i < lines.length - 1; i++) {
						linesEval.push(lines[i])
					}

					try {
						const text = eval('(function() {' + linesEval.join('\n') + '})()')

						if (typeof text != 'object') {
							throw new TypeError('Function must return 2 dimensioned array of strings! (got ' + (typeof text) + ')')
						}

						for (const str of (<string[][]> text)) {
							if (typeof str != 'object') {
								throw new TypeError('Function must return 2 dimensioned array of strings! (got ' + (typeof str) + ' in subarray!)')
							}

							annotations.push(new AnnotationCommentary(file, str))
						}
					} catch(err) {
						console.error('Error running documentation preprocessor:')
						console.error(linesEval.join('\n'))
						console.error('In file ' + file)
						console.error(err)
					}

					break
				}

				if (trim.toLowerCase() == '@doc') {
					break
				}
			}

			if (!bad) {
				lines.splice(0, 1)
				lines.pop()

				annotations.push(new AnnotationCommentary(file, lines))
			}
		}
	}
}

function addFile(file: string) {
	const list = eval('(function() {' + fs.readFileSync(file, {encoding: 'utf8'}) + '})()')

	for (const lines of list) {
		annotations.push(new AnnotationCommentary(file, lines.trim().split(/\r?\n/)))
	}
}

addFile('./docs/nbt.js')
addFile('./docs/camiwatchdog.js')
addFile('./docs/set.js')

if (annotations.length == 0) {
	console.log('No annotations with @doc found!')
	process.exit(0)
}

const root = new DocumentationRoot()

for (const annotation of annotations) {
	root.add(annotation)
}

root.generateFiles('./output')
