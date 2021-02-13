
-- Copyright (C) 2017-2020 DBotThePony

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

local VTF = {}
local VTFObject = {}

local Formats = {
	'IMAGE_FORMAT_NONE',
	'IMAGE_FORMAT_RGBA8888',
	'IMAGE_FORMAT_ABGR8888',
	'IMAGE_FORMAT_RGB888',
	'IMAGE_FORMAT_BGR888',
	'IMAGE_FORMAT_RGB565',
	'IMAGE_FORMAT_I8',
	'IMAGE_FORMAT_IA88',
	'IMAGE_FORMAT_P8',
	'IMAGE_FORMAT_A8',
	'IMAGE_FORMAT_RGB888_BLUESCREEN',
	'IMAGE_FORMAT_BGR888_BLUESCREEN',
	'IMAGE_FORMAT_ARGB8888',
	'IMAGE_FORMAT_BGRA8888',
	'IMAGE_FORMAT_DXT1',
	'IMAGE_FORMAT_DXT3',
	'IMAGE_FORMAT_DXT5',
	'IMAGE_FORMAT_BGRX8888',
	'IMAGE_FORMAT_BGR565',
	'IMAGE_FORMAT_BGRX5551',
	'IMAGE_FORMAT_BGRA4444',
	'IMAGE_FORMAT_DXT1_ONEBITALPHA',
	'IMAGE_FORMAT_BGRA5551',
	'IMAGE_FORMAT_UV88',
	'IMAGE_FORMAT_UVWQ8888',
	'IMAGE_FORMAT_RGBA16161616F',
	'IMAGE_FORMAT_RGBA16161616',
	'IMAGE_FORMAT_UVLX8888'
}

VTFObject.Formats = {}

for i = 1, #Formats do
	VTFObject.Formats[Formats[i]] = i - 2
	VTFObject.Formats[i - 2] = Formats[i]
end

VTFObject.Readers = {}
VTFObject.Readers.IMAGE_FORMAT_DXT1 = DLib.DXT1
VTFObject.Readers.IMAGE_FORMAT_DXT3 = DLib.DXT3
VTFObject.Readers.IMAGE_FORMAT_DXT5 = DLib.DXT5

function VTF:ctor(bytes)
	self.pointer = bytes:Tell()
	-- self.buffer = bytes

	local readHead = VTFObject.HeaderStruct(bytes)
	local readHead2, readHead3

	if readHead.version[2] >= 2 then
		readHead2 = VTFObject.HeaderStruct72(bytes)
	end

	if readHead.version[2] >= 3 then
		readHead3 = VTFObject.HeaderStruct73(bytes)
	end

	self.version_string = string.format('%d.%d', readHead.version[1], readHead.version[2])

	self.version_major = readHead.version[1]
	self.version_minor = readHead.version[2]

	self.width = readHead.width
	self.height = readHead.height
	self.flags = readHead.flags
	self.frames = readHead.frames
	self.first_frame = readHead.firstFrame
	self.reflectivity = Vector(1 - readHead.reflectivity[1], 1 - readHead.reflectivity[2], 1 - readHead.reflectivity[3])
	self.high_res_image_format = readHead.highResImageFormat
	self.low_res_image_format = readHead.lowResImageFormat
	self.low_width = readHead.lowResImageWidth
	self.low_height = readHead.lowResImageHeight
	self.mipmap_count = readHead.mipmapCount

	if readHead2 then
		self.depth = readHead2.depth
	else
		self.depth = 1
	end

	if readHead3 then
		self.num_resources = readHead3.numResources
	end

	self.faces = 1

	if bit.band(self.flags, 0x4000) == 0x4000 then
		self.faces = 6
	end

	assert(self.low_res_image_format == VTFObject.Formats.IMAGE_FORMAT_DXT1, 'self.low_res_image_format ~= VTFObject.Formats.IMAGE_FORMAT_DXT1 (' .. self.low_res_image_format .. ' ~= ' .. VTFObject.Formats.IMAGE_FORMAT_DXT1 .. ')')

	local resolutions = {}
	local w, h = self.width, self.height

	for mipmap = self.mipmap_count, 1, -1 do
		resolutions[mipmap] = {w, h}
		w = w / 2
		h = h / 2
	end

	self.mipmap_resolutions = resolutions
	self.mipmaps = {}
	self.mipmaps_obj = {}

	local reader = assert(VTFObject.Readers[VTFObject.Formats[self.high_res_image_format]], 'Unsupported image format ' .. VTFObject.Formats[self.high_res_image_format])

	if self.version_minor <= 2 then
		if bytes:Tell() < readHead.headerSize then
			bytes:Walk(readHead.headerSize - bytes:Tell())
		end

		-- DXT1: each block takes 64 bits of data, or 8 bytes
		-- width / 4 * height / 4 * 8
		-- skip it
		bytes:Walk(self.low_width * self.low_height / 2)

		-- from smallest to largest
		for mipmap = 1, self.mipmap_count do
			local w, h = resolutions[mipmap][1], resolutions[mipmap][2]

			-- from first to last
			for frame = 1, self.frames do
				-- from first to last
				for face = 1, self.faces do
					-- for each Z slice (smallest to largest)
					for zDepth = 1, self.depth do
						local walk = reader.CountBytes(w, h)
						self.mipmaps[mipmap] = DLib.BytesBufferView(bytes:Tell(), bytes:Tell() + walk, bytes)
						self.mipmaps_obj[mipmap] = reader(self.mipmaps[mipmap], w, h)
						bytes:Walk(walk)
					end
				end
			end
		end
	else
		self.resources = {}

		for i = 1, self.num_resources do
			table.insert(self.resources, VTFObject.ResourceInfoStruct(bytes))
		end
	end
end

VTFObject.HeaderStruct = DLib.BytesBuffer.CompileStructure([[
	char                            signature[4];       // File signature ("VTF\0"). (or as little-endian integer, 0x00465456)
	little endian unsigned int      version[2];         // version[0].version[1] (currently 7.2).
	little endian unsigned int      headerSize;         // Size of the header struct  (16 byte aligned; currently 80 bytes) + size of the resources dictionary (7.3+).
	little endian unsigned short    width;              // Width of the largest mipmap in pixels. Must be a power of 2.
	little endian unsigned short    height;             // Height of the largest mipmap in pixels. Must be a power of 2.
	little endian unsigned int      flags;              // VTF flags.
	little endian unsigned short    frames;             // Number of frames, if animated (1 for no animation).
	little endian unsigned short    firstFrame;         // First frame in animation (0 based).
	unsigned char                   padding0[4];        // reflectivity padding (16 byte alignment).
	float                           reflectivity[3];    // reflectivity vector.
	unsigned char                   padding1[4];        // reflectivity padding (8 byte packing).
	float                           bumpmapScale;       // Bumpmap scale.
	little endian unsigned int      highResImageFormat; // High resolution image format.
	unsigned char                   mipmapCount;        // Number of mipmaps.
	little endian unsigned int      lowResImageFormat;  // Low resolution image format (always DXT1).
	unsigned char                   lowResImageWidth;   // Low resolution image width.
	unsigned char                   lowResImageHeight;  // Low resolution image height.
]])

VTFObject.HeaderStruct72 = DLib.BytesBuffer.CompileStructure([[
	// 7.2+
	little endian unsigned short    depth;              // Depth of the largest mipmap in pixels.
														// Must be a power of 2. Is 1 for a 2D texture.
]])

VTFObject.HeaderStruct73 = DLib.BytesBuffer.CompileStructure([[
	// 7.3+
	little endian unsigned char     padding2[3];        // depth padding (4 byte alignment).
	little endian unsigned int      numResources;       // Number of resources this vtf has. The max appears to be 32.

	little endian unsigned char     padding3[8];        // Necessary on certain compilers
]])

VTFObject.ResourceInfoStruct = DLib.BytesBuffer.CompileStructure([[
	unsigned char                   tag[3];             // A three-byte "tag" that identifies what this resource is.
	unsigned char                   flags;              // Resource entry flags. The only known flag is 0x2, which indicates that no data chunk corresponds to this resource.
	little endian unsigned int      offset;             // The offset of this resource's data in the file.
]])

DLib.VTF = DLib.CreateMoonClassBare('VTF', VTF, VTFObject)
