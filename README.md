# RandomX FPGA

This is my first HDL Design, I would appreciate suggestions for improvement.

In order to make the development less time consuming, I skipped the dataset generation.
Instead, the dataset is sent to the FPGA DRAM.

A digital design is much more expensive to maintain so I let the community do further updates and changes.


## How it works?

RandomX has been considered ASIC and FPGA resistance due to the amount of needed memory and the VM.

With new accelerator cards, The DRAM won't be an issue since you can use AWS F1 with 64GB memory and if you need more, You are able to connect different Instances.

### What about the VM?

Quote from RandomX README:

> RandomX generates multiple unique programs for every hash, so FPGAs cannot dynamically reconfigure their circuitry because typical FPGA takes tens of seconds to load a bitstream. It is also not possible to generate bitstreams for RandomX programs in advance due to the sheer number of combinations (there are 2^512 unique programs).

It appears the developers assumed that to run the instructions we need to implement every possible program.

Just like the VM itself, We need to only implement 29 instructions. For instance, if FPGA encountered an OP Code that corresponds to adding values, We only need to implement the ADD operation.

Overall an FPGA has a very limited clock speed than a CPU, Only an ASIC can outperform it.

<hr/>

I also implement it in python to have better understanding of the algorithm for easier hardware design:

https://github.com/MainSilent/py-RandomX

### Credit:

Blake2: https://github.com/christian-krieg/blake2