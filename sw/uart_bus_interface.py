import serial
import time

##################################################################
# UartBusInterface: UART -> Bus master interface
##################################################################
class UartBusInterface:
    ##################################################################
    # Construction
    ##################################################################
    def __init__(self, iface = '/dev/ttyUSB1', baud = 115200):
        self.interface  = iface
        self.baud       = baud
        self.uart       = self.uart = serial.Serial(
            port=self.interface,
            baudrate=self.baud,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            bytesize=serial.EIGHTBITS,
            timeout=1,
        )
        self.uart.flush()
        self.prog_cb    = None
        self.CMD_WRITE  = 0x10
        self.CMD_READ   = 0x11
        self.CMD_WRITE_KH = 0x12
        self.CMD_READ_KH  = 0x13
        self.MAX_SIZE   = 65536
        self.BLOCK_SIZE = 16*1024
        self.GPIO_ADDR  = 0xF0000000
        self.STS_ADDR   = 0xF0000004

        self.connect()

    ##################################################################
    # set_progress_cb: Set progress callback
    ##################################################################
    def set_progress_cb(self, prog_cb):
        self.prog_cb    = prog_cb

    ##################################################################
    # connect: Open serial connection
    ##################################################################
    def connect(self, timeout=5.0, retry_interval=0.2):
        if not self.uart.is_open:
            self.uart.open()

        # Check status register
        deadline = time.monotonic() + timeout
        while True:
            self.uart.reset_input_buffer()
            value = self.read32(self.STS_ADDR)
            if (value & 0xFFFF0000) == 0xcafe0000:
                self.uart.flush()
                return
            if time.monotonic() >= deadline:
                raise Exception("Target not responding correctly, check interface / baud rate...")
            time.sleep(retry_interval)

    ##################################################################
    # read32: Read a word from a specified address
    ##################################################################
    def read32(self, addr):
        # Connect if required
        if self.uart == None:
            self.connect()

        # Send read command
        len = 4
        cmd = bytearray([self.CMD_READ, 
                        (len  >> 8)  & 0xFF,
                        (len  >> 0)  & 0xFF,
                        (addr >> 24) & 0xFF, 
                        (addr >> 16) & 0xFF, 
                        (addr >>  8) & 0xFF,
                        (addr >>  0) & 0xFF])
        self.uart.write(cmd)

        # Flush to ensure the command is actually sent and not cached by the kernel
        self.uart.flush()

        value = int.from_bytes(self.uart.read(4), byteorder="little")
        return value

    ##################################################################
    # write32: Write a word to a specified address
    ##################################################################
    def write32(self, addr, value):
        # Connect if required
        if self.uart == None:
            self.connect()

        # Send write command
        len = 4
        cmd = bytearray([self.CMD_WRITE,
                        (len   >> 8)  & 0xFF,
                        (len   >> 0)  & 0xFF,
                        (addr  >> 24) & 0xFF,
                        (addr  >> 16) & 0xFF,
                        (addr  >> 8)  & 0xFF,
                        (addr  >> 0)  & 0xFF,
                        (value >> 0)  & 0xFF, 
                        (value >> 8)  & 0xFF, 
                        (value >> 16) & 0xFF, 
                        (value >> 24) & 0xFF])
        self.uart.write(cmd)
        self.uart.flush()

    ##################################################################
    # write: Write a block of data to a specified address
    ##################################################################
    def write(self, addr, data, length, addr_incr=True, max_block_size=-1):
        # Connect if required
        if self.uart == None:
            self.connect()

        # Write blocks
        idx       = 0
        remainder = length

        if self.prog_cb != None:
            self.prog_cb(0, length)

        if max_block_size == -1:
            max_block_size = self.BLOCK_SIZE
        elif max_block_size > self.MAX_SIZE:
            max_block_size = self.MAX_SIZE

        while remainder > 0:
            l = max_block_size
            if l > remainder:
                l = remainder

            cmd = bytearray(3 + 4 + l)
            cmd[0] = self.CMD_WRITE if addr_incr else self.CMD_WRITE_KH
            cmd[1] = (l >> 8) & 0xFF
            cmd[2] = l & 0xFF
            cmd[3] = (addr >> 24) & 0xFF
            cmd[4] = (addr >> 16) & 0xFF
            cmd[5] = (addr >> 8)  & 0xFF
            cmd[6] = (addr >> 0)  & 0xFF

            for i in range(l):
                cmd[7+i] = data[idx + i]

            # Write to serial port
            self.uart.write(cmd)
            self.uart.flush()

            # Update display
            if self.prog_cb != None:
                self.prog_cb(idx, length)

            if addr_incr:
                addr  += l
            remainder -= l
            idx       += l

    ##################################################################
    # read: Read a block of data from a specified address
    ##################################################################
    def read(self, addr, length, addr_incr=True, max_block_size=-1):
        # Connect if required
        if self.uart == None:
            self.connect()

        remainder = length
        data      = bytearray()

        if self.prog_cb != None:
            self.prog_cb(0, length)

        if max_block_size == -1:
            max_block_size = self.BLOCK_SIZE
        elif max_block_size > self.MAX_SIZE:
            max_block_size = self.MAX_SIZE

        while remainder > 0:
            l = max_block_size if max_block_size < remainder else remainder

            cmd = bytearray(3 + 4)
            cmd[0] = self.CMD_READ if addr_incr else self.CMD_READ_KH
            cmd[1] = (l >> 8) & 0xFF
            cmd[2] = l & 0xFF
            cmd[3] = (addr >> 24) & 0xFF
            cmd[4] = (addr >> 16) & 0xFF
            cmd[5] = (addr >> 8)  & 0xFF
            cmd[6] = (addr >> 0)  & 0xFF

            # Write to serial port
            self.uart.write(cmd)

            # Flush to ensure the command is actually sent and not cached by the kernel
            self.uart.flush()

            # Read block response
            chunk_remaining = l
            while chunk_remaining > 0:
                chunk = self.uart.read(chunk_remaining)
                if not chunk:
                    raise IOError("UART timeout")
                data.extend(chunk)
                chunk_remaining -= len(chunk)

            # Update display
            if self.prog_cb != None:
                self.prog_cb(len(data), length)

            if addr_incr:
                addr  += l
            remainder -= l

        return data

    ##################################################################
    # read_gpio: Read GPIO bus
    ##################################################################
    def read_gpio(self):
        return self.read32(self.GPIO_ADDR)

    ##################################################################
    # write_gpio: Write a byte to GPIO
    ##################################################################
    def write_gpio(self, value):
        self.write32(self.GPIO_ADDR, value)
