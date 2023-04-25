# renode-dpi-examples

Copyright (c) 2023 [Antmicro](https://www.antmicro.com)

Example integration between Renode and a Verilog model using DPI (SystemVerilog Direct Programming Interface) calls.

The provided `cosim-axi.robot` file, which is a RobotFramework test suite, contains a set of tests verifying data exchanged between Renode's memory and a Verilog RAM model, handled by cosim-bfm-library in the form of AXI4 bus transactions.

The `Cosim BFM library` is a package to provide HW-SW co-simulation between the HDL (Hardware Description Language) simulator and the host program, where BFM (Bus Functional Model or Bus Functional Module) generates bus transactions by interacting with the host program in C.
Communication is based on pre-defined packets exchanged between HW/SW sides over an IPC channel.

To run the tests two things have to be present:
* `libcosim_bfm.so` which is generated from the `cosim_bfm_library` submodule (detailed build instructions are below)
* `Vcosim_bfm_axi_dpi` which is the compiled verilog model, generated from the `verilator-build` directory in the `cosim_bfm_library` submodule

## cosim_bfm_library details

### IPC flow

In order to send/receive packets over IPC channel, the channel should be built beforehand.
After establishing channel, message passing mechanism is used to communicate between two parties.
Each transaction consists of two messages; one is request and the other is response.
For write transaction, all necessary information including address and data are packed in to the packet and the packet is forwarded to the receiver.
The receiver prepares a return packet, i.e., response packet and sends it back to the sender.
For read transaction, request packet is forwarded to the receiver and then the receiver returns response packet that contains read data.

### Bus transaction routines for C/C++

More details can be found in `cosim_bfm_api.c` source file.

* `bfm_open()` tries to create and open communication channel to the hardware simulator, where cid specifies channel identification and 0 by default.
It returns 0 on success or negative number on failure
```
bfm_open( cid=0, rigor=False, verbose=False )
```

* `bfm_close()` closes the communication channel with the channel cid.
It returns 0 on success or negative number on failure
```
bfm_close( cid=0, rigor=False, verbose=False )
```

* `bfm_barrier()` waits for joining the hardware simulator.
It returns 0 on success or negative number on failure
```
bfm_barrier( cid=0, rigor=False, verbose=False )
```

* `bfm_set_verbose()` sets verbosity level, where `level' is 0 by default to depress message.
It returns 0 on success or negative number on failure
```
bfm_set_verbose( level=0, rigor=False, verbose=False )
```

* `bfm_write()`  makes HW BFM generate a burst write transaction
  * `addr` for the starting address that should be aligned with the `sz`
  * `data` for the buffer containing byte-stream data to be written, where the size of `data` buffer should be `sz x length`
  * `sz` for the number of bytes to be written at a each transaction and can be 1, 2, and 4
  * returns 0 on success, otherwise negative number
```
int bfm_write( uint32_t     addr
             , uint8_t     *data
             , unsigned int sz
             , unsigned int length);

```

* `bfm_read()` makes HW BFM generate a burst read transaction
  * `addr` for the starting address that should be aligned with the `sz`
  * `data` for the buffer to be contain byte-stream data after read, where the size of `data` buffer should be `sz x length`
  * `sz` for the number of bytes to be written at each transaction and can be 1, 2, and 4
  * returns 0 on success, otherwise negative number
```
int bfm_read ( uint32_t     addr
             , uint8_t     *data
             , unsigned int sz
             , unsigned int length);
```


### DPI functions for hardware side

More details can be found in files `cosim_bfm_dpi.c` and `cosim_bfm_axi_core.v`.
Following DPI functions correspond to the that of C API.

* `cosim_ipc_open()` creates and opens IPC channel
```
import "DPI-C" cosim_ipc_open   =function int cosim_ipc_open   (input int cid);
```

* `cosim_ipc_close()` closes IPC channel
```
import "DPI-C" cosim_ipc_close  =function int cosim_ipc_close  (input int cid);
```

* `cosim_ipc_barrier()` waits for joining the software program
```
import "DPI-C" cosim_ipc_barrier=function int cosim_ipc_barrier(input int cid);
```

* `cosim_ipc_get()` receives a packet through IPC channel and carries out operation specified by `pkt_cmd`, which includes read and write transaction
```
import "DPI-C" cosim_ipc_get    =function int cosim_ipc_get(
                   input  int       cid  // IPC channel identification
                 , output int       pkt_cmd  // see cosim_bfm_defines.vh
                 , output int       pkt_size  // 1, 2, 4
                 , output int       pkt_length  // burst length
                 , output int       pkt_ack 
                 , output int       pkt_attr
                 , output int       pkt_trans_id
                 , output int       pkt_addr 
                 , output bit [7:0] pkt_data[]  // open-array
                 );
```

* `cosim_ipc_put()` sends a packet through IPC channel and it is usually called after `cosim_ipc_get()`
```
import "DPI-C" cosim_ipc_put  =function int cosim_ipc_put(
                   input  int       cid
                 , input  int       pkt_cmd
                 , input  int       pkt_size // 1, 2, 4
                 , input  int       pkt_length // burst length
                 , input  int       pkt_ack
                 , input  int       pkt_attr
                 , input  int       pkt_trans_id
                 , input  int       pkt_addr
                 , input  bit [7:0] pkt_data[] // open-array
                );
```

### Verilog code for read and write transactions

More details can be found in files `cosim_bfm_axi_core.v` and `cosim_bfm_axi_tasks.v`.

* executed on a read request
```
axi_read_task( tid
             , addr
             , size
             , leng
             , attr[1:0]); // burst type: 1=incremental
```

* executed on a write request
```
axi_write_task( tid
              , addr
              , size
              , leng
              , attr[1:0]); // burst type: 1=incremental
```


## Build process

### 1) Build and install `verilator`:
```
sudo apt update
sudo apt install -y git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1 autoconf flex bison perl perl-doc numactl libfl2 libfl-dev help2man

git clone https://github.com/verilator/verilator
pushd verilator
autoconf
./configure CC='ccache g++'
make -j `nproc` && sudo make install

export PATH=`pwd`/bin:$PATH
export VERILATOR_ROOT="$PWD"
popd
```

### 2) Build `cosim-bfm-library` and compile the verilog model
```
pushd cosim_bfm_library
pushd lib_bfm
make -f Makefile.lib_bfm cleanup
make INCLUDES=../../verilator/include/vltstd -f Makefile.lib_bfm
make -f Makefile.lib_bfm install
popd
pushd verilator-build
verilator --timing --cc -Wno-WIDTH cosim_bfm_axi_dpi.sv top.v mem_axi_beh.v -exe Vcosim_bfm_axi_dpi__main.cpp cosim_bfm_api.c cosim_bfm_dpi.c cosim_ipc.c
make -C obj_dir/ -f Vcosim_bfm_axi_dpi.mk
popd
popd
```

## Usage

To run the test suite:

### 1) Prepare Renode
```
wget --progress=dot:giga https://dl.antmicro.com/projects/renode/builds/custom/renode-1.13.2+20230411git4d56db3f.linux-portable.tar.gz
mkdir -p renode
tar xf renode-1.13.2+20230411git4d56db3f.linux-portable.tar.gz --strip-components 1 -C renode
rm renode-1.13.2+20230411git4d56db3f.linux-portable.tar.gz
pip install -r renode/tests/requirements.txt
```

### 2) Copy `libcosim_bfm.so` to the renode directory from the previous step
```
cp `find . -name libcosim_bfm.so` renode/
```

### 3) Run with renode-test:
```
renode/renode-test --variable=COSIM_BIN:`find . -name Vcosim_bfm_axi_dpi` cosim-axi.robot
```
