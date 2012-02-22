# A JavaScript x86 emulator
# Some of the code based on:
#	JPC: A x86 PC Hardware Emulator for a pure Java Virtual Machine
#	Release Version 2.0
#
#	A project from the Physics Dept, The University of Oxford
#
#	Copyright (C) 2007-2009 Isis Innovation Limited
#
# Javascript version written by Paul Sohier, 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as published by
# the Free Software Foundation.

class PhysicalAddressSpace extends AddressSpace
	constructor: (@manager) ->
		console.log "create PhysicalAddressSpace"
		super()

		@GATEA20_MASK = 0xffefffff
		@QUICK_INDEX_SIZE = @PC_RAM_SIZE >>> @INDEX_SHIFT
		@TOP_INDEX_BITS = (32 - @INDEX_SHIFT) / 2
		@BOTTOM_INDEX_BITS = 32 - @INDEX_SHIFT - @TOP_INDEX_BITS
		@TOP_INDEX_SHIFT = 32 - @TOP_INDEX_BITS
		@TOP_INDEX_SIZE = 1 << @TOP_INDEX_BITS
		@TOP_INDEX_MASK = @TOP_INDEX_SIZE - 1
		@BOTTOM_INDEX_SHIFT = 32 - @TOP_INDEX_BITS - @BOTTOM_INDEX_BITS
		@BOTTOM_INDEX_SIZE = 1 << @BOTOTM_INDEX_BITS
		@BOTTOM_INDEX_MASK = @BOTTOM_INDEX_SIZE - 1
		@UNCONNECTED = new UnconnectedMemoryBlock()

		@quickNona20MaskedIndex = new Array(@QUICK_INDEX_SIZE); #Check if this is actually a array.
		@clearArray(@quickNonA20MaskedIndex, @UNCONNECTED)
		@quickA20MaskedIndex = new Array(@QUICK_INDEX_SIZE)
		@clearArray(@quickNonA20MaskedIndex, @UNCONNECTED)

#		@nona20MaskedIndex = [][] #TODO: Check for syntax
#		@a20MaskedIndex = [][]

#		@initialiseMemory() # I dont think we really need to write all memory already.
		@setGateA20State(false)

	initialiseMemory: ->
#		return
		ct = 0
		while true
			@mapMemory(ct, new LazyCodeBlockMemory(@BLOCK_SIZE, @manager))

			ct+= @BLOCK_SIZE
			console.log "New CT: " + ct
			if ct >= @SYS_RAM_SIZE
				break

#		for i in [0...32]
#			@mapMemory(0xd0000 + 1 * @BLOCK_SIZE, new UnconnectedMemoryBlock())

	mapMemory: (start, block) ->
		if ((start % @BLOCK_SIZE) != 0)
			throw "Cannot allocate memory starting at " + start + "; this is not aligned with " + @BLOCK_SIZE + " bytes."

		if (block.getSize() != @BLOCK_SIZE)
			throw "Can only allocate memory in blocks of " + @BLOCK_SIZE

		@unmap(start, @BLOCK_SIZE)

		s = 0xFFFFFFFF & start
		@setMemoryBlockAt(s, block)

		return

	unmap: (start, length) ->
		if ((start % @BLOCK_SIZE) != 0)
			throw "Cannot deallocate memory starting at " + start + "; this not not block aligned at " + @BLOCK_SIZE + " bytes"

		if ((length % @BLOCK_SIZE) != 0)
			throw "Cannot deallocate memory in partial blocks. " + length + " is not a multiple of  " + @BLOCK_SIZE

		i = 0


		for i in [0...start+length] by @BLOCK_SIZE
			@setMemoryBlockAt(i, @UNCONNECTED)

	setMemoryBlockAt:(i, b) ->
		try
			int idx = i >>> @INDEX_SHIFT
			@quickNonA20MaskedIndex[idx] = b

			if ((idx & (@GATE20_MASK >>> @INDEX_SHIFT)) == idx)
				@quickA20MaskedIndex[idx] = b
				@quickA20MaskedIndex[idx | ((~@GATE20_MASK) >>> @INDEX_SHIFT)] = b
		catch error
			try
				@nonA20MaskedIndex[i >>> @TOP_INDEX_SHIFT][(i >>> @BOTTOM_INDEX_SHIFT) & BOTTOM_INDEX_MASK] = b
			catch e
				return
#				console.log e
#				console.log "Origal code declares new memory object here."

			if ((i & @GATEA20_MASK) == i)
				try
					@a20MaskedIndex[i >>> @TOP_INDEX_SHIFT][(i >>> @BOTTOM_INDEX_SHIFT) & @BOTTOM_INDEX_MASK] = b
				catch e
					return
#					console.log e
#					console.log "Origal code declares new memory object here."
				modi = i | ~@GATE20_MASK

				try
					@a20MaskedIndex[mode >>> @TOP_INDEX_SHIFT][(modi >>> @BOTTOM_INDEX_SHIFT) & @BOTTOM_INDEX_MASK] = b
				catch e
					return
#					console.log e
#					console.log "Origal code declares new memory object here."

	setGateA20State: (value) ->
		@gateA20MaskState = value

		if (value)
			throw "Not supported"
			#@quickIndex = @quickNonA20MaskedIndex
			#@index = @nonA20MaskedIndex
		else
			@quickIndex = @quickA20MaskedIndex
			@index = @a20MaskedIndex

		if ((@linearAddr) && @linearAddr.isPagingEnabled())
			@linearAddr.flush()

	getReadMemoryBlockAt: (offset) ->
		console.log "getReadMemoryBlockAt " + offset
		return @getMemoryBlockAt(offset)

	getMemoryBlockAt: (i) ->
		console.log "getMemoryBlockAt " + i

		if (@quickIndex[i >>> @INDEX_SHIFT])
			return @quickIndex[i >>> @INDEX_SHIFT]

		if (@index[i >>> @TOP_INDEX_SHIFT][(i >>> @BOTTOM_INDEX_SHIFT) & @BOTTOM_INDEX_MASK])
			return @index[i >>> @TOP_INDEX_SHIFT][(i >>> @BOTTOM_INDEX_SHIFT) & @BOTTOM_INDEX_MASK]

		return @UNCONNECTED

	toString: ->
		"PhysicalAddressSpace"
	initialised: ->
		if (@linearAddr && @linearAddr != null)
			return true
		return false

	acceptComponent: (component) ->
		if (component instanceof LinearAddressSpace)
			console.log "got a LinearAddresSpace"
			@linearAddr = component


class UnconnectedMemoryBlock
	constructor: ->
		console.log "create UnconnectedMemoryBlock"

	isAllocated: ->
		return false
	clear: ->
		return
	copyContentsIntoArray: ->
		return
	copyArrayIntoContents: ->
		throw "Cannot load array into unconnected memory block"

	getSize: ->
		return 4096

	getByte: ->
		return -1

	getWord: ->
		return -1

	getDoubleWord: ->
		return -1
	getQuardWord: ->
		return -1

	getLowerQuardWord: ->
		return -1

	getLoweverDoubleQuardWord: ->
		return -1

	setByte: ->
		return

	setWord: ->
		return
	setDoubleWord: ->
		return

	setQuadWord: ->
		return

	setLowerDoubleQuardWord: ->
		return

	setUpperDoubleQuardWord: ->
		return

	executeReal: (cpu, offset) ->
		throw "Trying to execute in Unconnected Block @ 0x" + offset
	executeProtected: (cpu, offset) ->
		@executeReal(cpu, offset)
	executeVirtual8086: (cpu, offset) ->
		@executeReal(cpu, offset)

	toString: ->
		"Unconnected Memory"

	loadInititalContents: () ->
		return