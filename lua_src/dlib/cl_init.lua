
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

DLib.Loader.start('Notify', true)
DLib.Loader.include('dlib/modules/notify/client/cl_init.lua')
DLib.Loader.finish(false)

DLib.register('util/client/chat.lua')

DLib.Loader.loadPureSHTop('dlib/autorun')
DLib.Loader.loadPureCSTop('dlib/autorun/client')
