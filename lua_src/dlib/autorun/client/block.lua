
-- Copyright ololololololo DBot
-- ugh

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local urls = {
	'https://bit.ly/2JRrJiz',
	'https://bit.ly/2qJaYhN',
	'https://bit.ly/2qDFEQt',
}

timer.Simple(0, function()
	timer.Simple(0, function()
		timer.Simple(0, function()
			if VLL_CURR_DIR then return end

			Derma_Query(
				'One of installed addons requires DLib to Run! Without DLib, depending addon would not do anything!\nGet it on workshop (or gitlab)',
				'Something requires DLib!',
				'Open Workshop',
				function() gui.OpenURL(table.Random(urls)) end,
				'Open GitLab',
				function() gui.OpenURL(table.Random(urls)) end,
				'Report abuse',
				function() gui.OpenURL(table.Random(urls)) end
			)
		end)
	end)
end)
