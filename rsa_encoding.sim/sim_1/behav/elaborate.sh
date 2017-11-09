#!/bin/bash -f
xv_path="/opt/Xilinx/Vivado/2017.2"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xelab -wto 8f3fb3cc101f4ccb8d4db0092a269e4b -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot RSACoreTestBench_behav xil_defaultlib.RSACoreTestBench -log elaborate.log
