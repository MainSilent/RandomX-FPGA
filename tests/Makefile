GREEN="\033[0;32m"
NOCOLOR="\033[0m"

Blake2File = ../src/blake2b.vhd tb_blake2/tb_blake2b.vhd
AESCore = ../src/AES/sbox.vhd ../src/AES/core.vhd
GenScratchpadFile = ../src/AES/fillAes1Rx4.vhd ../src/AES/hashAes1Rx4.vhd tb_scratchpad.vhd
CompileFile = ../src/common.vhd ../src/compiler.vhd ../src/AES/fillAes4Rx4.vhd tb_program/c_opcode.vhd tb_program/c_other.vhd tb_program/c_regn.vhd tb_compile.vhd
ExecFile = $(GenScratchpadFile) $(CompileFile) ../src/adapt512x64.vhd ../src/execute.vhd tb_exec.vhd
RunFile = $(ExecFile) ../src/run.vhd dataset.vhd tb_run.vhd

all: clean blake2_test scratchpad_test compile_test exec_test run_test clean

blake2_test:
	ghdl -s --std=08 $(Blake2File)
	ghdl -a --std=08 $(Blake2File)
	ghdl -e --std=08 tb_blake2b
	ghdl -r --std=08 tb_blake2b --wave=tb_blake2b.ghw
	@echo ${GREEN}"Test blake2 Done.\n"${NOCOLOR}

scratchpad_test:
	ghdl -s --std=08 bram.vhd $(AESCore) $(GenScratchpadFile)
	ghdl -a --std=08 bram.vhd $(AESCore) $(GenScratchpadFile)
	ghdl -e --std=08 tb_scratchpad
	ghdl -r --std=08 tb_scratchpad --wave=tb_scratchpad.ghw --stop-delta=5000000
	@echo ${GREEN}"Test Scratchpad Generation Done.\n"${NOCOLOR}

compile_test:
	ghdl -s --std=08 $(AESCore) $(CompileFile)
	ghdl -a --std=08 $(AESCore) $(CompileFile)
	ghdl -e --std=08 tb_compile
	ghdl -r --std=08 tb_compile --wave=tb_compile.ghw
	@echo ${GREEN}"Test Compile Done.\n"${NOCOLOR}

exec_test:
	ghdl -s --std=08 bram.vhd $(AESCore) $(ExecFile)
	ghdl -a --std=08 bram.vhd $(AESCore) $(ExecFile)
	ghdl -e --std=08 tb_exec
	ghdl -r --std=08 tb_exec --wave=tb_exec.ghw  --stop-delta=5000000
	@echo ${GREEN}"Test Exec Done.\n"${NOCOLOR}

run_test:
	ghdl -s --std=08 $(AESCore) $(RunFile)
	ghdl -a --std=08 $(AESCore) $(RunFile)
	ghdl -e --std=08 tb_run
	ghdl -r --std=08 tb_run --wave=tb_run.ghw  --stop-delta=5000000
	@echo ${GREEN}"Test Run Done.\n"${NOCOLOR}

clean:
	rm *.cf *.ghw -f