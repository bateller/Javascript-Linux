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

class IOPortHandler
	constructor: () ->
		@MAX_IOPORTS = 65536
		@defaultDevice = new UnconnectedIOPort()
		@ioPortDevice = new Array(@MAX_IOPORTS)


	configure: ->
		log "IOPortHandler configure"

	toString: ->
		"IOPortHandler"

	registerIOPortCapable: (device) ->
		data = device.ioPortsRequested()

		if (!data || data == null)
			return

		for i in [0...data.length]
			port = data[i]
			if (!@ioPortDevice[port])
				log "Added port #{port} to device #{device}"
				@ioPortDevice[port] = device
	initialised: ->
		return true

	check: (address) ->
		log "Checking for read/write to address: #{address}"
		if (!@ioPortDevice[address])
			log "Address unconnected set to: #{address}. TODO: Check if it is ok for this to happen :)."
			@ioPortDevice[address] = @defaultDevice

	ioPortWriteWord: (address, data) ->
		@check(address)

		@ioPortDevice[address].ioPortWriteWord(address, data)

	ioPortWriteByte: (address, data) ->
		@check(address)
		@ioPortDevice[address].ioPortWriteByte(address, data)

	ioPortReadWord: (address) ->
		@check(address)

		return @ioPortDevice[address].ioPortReadWord(address)


	ioPortReadByte: (address) ->
		@check(address)

		return @ioPortDevice[address].ioPortReadByte(address)

class UnconnectedIOPort
	ioPortReadByte: ->
		log "Trying to read from unconnectedIOPort"
		return 0xff
	ioPortReadWord: ->
		log "Trying to read from unconnectedIOPort"
		return 0xffff
	ioPortReadLong: ->
		log "Trying to read from unconnectedIOPort"
		return 0xffffffff

	ioPortWriteByte: ->
		log "Trying to write to unconnectedIOPort"
	ioPortWriteWord: ->
		log "Trying to write to unconnectedIOPort"

	ioPortWriteLong: ->
		log "Trying to write to unconnectedIOPort"

	ioPortsRequested: ->
		return null
