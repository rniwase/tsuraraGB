#!/usr/bin/env python3

import sys
import logging
import argparse
from os import environ
from typing import Optional
from pyftdi.misc import to_bool
from pyftdi.spi import SpiController


class SPIFlashProgrammer:
    def __init__(self):
        self._spi = SpiController()
        self._port = None
        self._gpio = None

    def open(self):
        url = environ.get("FTDI_DEVICE", "ftdi:///1")
        debug = to_bool(environ.get("FTDI_DEBUG", "off"))
        self._spi.configure(url, debug=debug)
        self.set_port(cs=0, freq=6E6, mode=0)
        self._gpio = self._spi.get_gpio()

    def set_port(self, cs: int, freq: Optional[float] = None, mode: int = 0):
        self._port = self._spi.get_port(cs=cs, freq=freq, mode=mode)

    def read_status(self) -> int:
        reg = self._port.exchange([0x05], 9)[0]
        return reg

    def wait_busy(self, attempts: int = 20000) -> None:
        for i in range(attempts):
            reg = self.read_status()
            busy = reg & 0x01
            if busy == 0:
                return
        raise Exception("Busy status timed out")

    def write_enable(self) -> None:
        self.wait_busy()
        self._port.exchange([0x06])
        wel = (self.read_status() & 0x02) >> 1
        if wel == 0:
            raise Exception("Illegal status register (WEL={})".format(wel))

    def write_disable(self) -> None:
        self.wait_busy()
        self._port.exchange([0x04])
        wel = (self.read_status() & 0x02) >> 1
        if wel == 1:
            raise Exception("Illegal status register (WEL={})".format(wel))

    def read_id(self) -> bytes:
        return self._port.exchange([0x9f], 3)

    def check_id(self, ident: bytes) -> None:
        r_ident = self.read_id()
        if ident != r_ident:
            raise Exception(
                "Invalid JEDEC ID (Manufacturer ID:0x{:02X}, Device ID:0x{:02X}, UID:0x{:02X})".format(
                    r_ident[0], r_ident[1], r_ident[2]))

    def soft_reset(self) -> None:
        self._port.exchange([0x66])  # Enable reset
        self._port.exchange([0x99])  # Perform reset
        self.wait_busy()

    def chip_erase(self) -> None:
        self.write_enable()
        self.wait_busy()
        self._port.exchange([0x60])
        self.wait_busy()

    def page_program(self, offset: int, data: bytes) -> None:
        self.write_enable()
        # The maximum size of one operation is 256 bytes
        for i in range(int(len(data) / 256) + 1):
            self.wait_busy()
            self.write_enable()
            self._port.exchange(bytes([0x02]) + (offset + (i * 256)).to_bytes(3, "big") + data[i * 256:(i + 1) * 256])
        self.wait_busy()
        self.write_disable()

    def read_data(self, offset: int, size: int) -> bytes:
        data = b""
        for i in range(int(size / 256) + 1):
            self.wait_busy()
            data += self._port.exchange(bytes([0x03]) + (offset + (i * 256)).to_bytes(3, "big"), 256)
        self.wait_busy()
        return data[:size]

    def set_gpio(self, pins: int, direction: int) -> None:
        self._gpio.set_direction(pins, direction)
    
    def write_gpio(self, output: int) -> None:
        self._gpio.write(output)

    def close(self) -> None:
        self._spi.terminate()


def main():
    exit_status = 0
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    parser = argparse.ArgumentParser()
    parser.add_argument("--file", nargs='*', help="files to program")
    parser.add_argument("--offset", nargs='*', help="offset addresses to program")
    parser.add_argument("--erase", action="store_true")
    parser.add_argument("--verify", action="store_true")

    args = parser.parse_args()

    if args.file is None:
        logger.error("File name not specified")
        parser.print_usage()
        sys.exit(1)

    if args.offset is None:
        logger.error("Offset not specified")
        parser.print_usage()
        sys.exit(1)

    if len(args.file) != len(args.offset):
        logger.error("The number of filenames does not match the number of offsets")
        parser.print_usage()
        sys.exit(1)

    try:
        binaries = [open(f, "rb").read() for f in args.file]
        offsets = [int(i, 0) for i in args.offset]
    except Exception as e:
        logger.error(e)
        sys.exit(1)

    spi = SPIFlashProgrammer()

    try:
        spi.open()
    except Exception as e:
        logger.error(e)
        sys.exit(1)

    try:
        spi.write_gpio(0x00)
        spi.set_gpio(0x10, 0x10)  # assert ADBUS4 for iCE40UP5K CRESET

        logger.info("Check JEDEC ID...")
        spi.check_id(bytes([0xEF, 0x40, 0x14]))  # for W25Q80DVSSIG

        logger.info("Reset device...")
        spi.soft_reset()

        if args.erase:
            logger.info("Erase device...")
            spi.chip_erase()

        for (file, in_data, ofs) in zip(args.file, binaries, offsets):
            logger.info("Program: 0x{:06X} - 0x{:06X} ... {}".format(ofs, ofs + len(in_data) - 1, file))
            spi.page_program(ofs, in_data)
            if args.verify:
                logger.info("Verify : 0x{:06X} - 0x{:06X} ... {}".format(ofs, ofs + len(in_data) - 1, file))
                r_data = spi.read_data(ofs, len(in_data))
                if r_data != in_data:
                    logger.error("Failed verification!")
                    exit_status = 1

    except Exception as e:
        logger.error(e)
        exit_status = 1

    finally:
        spi.set_gpio(0x10, 0x00)  # negate ADBUS4 for iCE40UP5K CRESET
        spi.close()

    if exit_status != 0:
        logger.error("Program completed with some error")
    else:
        logger.info("Program completed successfully")
    sys.exit(exit_status)


if __name__ == "__main__":
    main()
