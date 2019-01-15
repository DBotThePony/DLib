
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

const findCommentaries = /--\[\[[^\]]*\]{2}/gm
const annotations = []

for (const file of filesToParse) {
	const read = fs.readFileSync(file, {encoding: 'utf8'})
	const match = read.match(findCommentaries)

	if (match) {
		//console.log(match)

		for (const commentary of match) {
			let bad = false
			const lines = commentary.split(/\r?\n/)

			for (const line of lines) {
				if (line.trim().match(/[a-z]/i) && line.trim().toLowerCase() != '@doc') {
					bad = true
					break
				}

				if (line.trim().toLowerCase() == '@doc') {
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

if (annotations.length == 0) {
	console.log('No annotations with @doc found!')
	process.exit(0)
}

const root = new DocumentationRoot()

for (const annotation of annotations) {
	root.add(annotation)
}

root.generateFiles('./output')
