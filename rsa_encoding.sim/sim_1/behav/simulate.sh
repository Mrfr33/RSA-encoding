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
ExecStep $xv_path/bin/xsim RSACoreTestBench_behav -key {Behavioral:sim_1:Functional:RSACoreTestBench} -tclbatch RSACoreTestBench.tcl -view /home/magnus/dokumenter/design-av-digitale-system-1/rsa_encoding/dp_init.wcfg -view /home/magnus/dokumenter/design-av-digitale-system-1/rsa_encoding/datapath_waveform.wcfg -log simulate.log
