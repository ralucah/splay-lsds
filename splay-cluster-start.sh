#!/bin/bash
SPLAY_INSTALL_DIR="/home/splayd/daemon/"
function usage {
  echo "Usage: ./splay-cluster-start.sh machine_id splayds_per_machine splay_ctrl_ip"
  exit 1
}
if [ $# -lt 3 ] ; then
  usage
fi
mkdir -p ~/local_splay_cluster/template/
cd ~/local_splay_cluster/template/
cp $SPLAY_INSTALL_DIR/jobd.lua .
cp $SPLAY_INSTALL_DIR/jobd .
cp $SPLAY_INSTALL_DIR/splayd.lua .
cp $SPLAY_INSTALL_DIR/splayd .
cp $SPLAY_INSTALL_DIR/settings.lua .
cp $SPLAY_INSTALL_DIR/*pem .
sed -i  s/"splayd.settings.key = \"local\""/"splayd.settings.key = \"host_NODE_NUMBER_GOES_HERE\""/ settings.lua
sed -i  s/"splayd.settings.name = \"my name\""/"splayd.settings.name = \"host_NODE_NUMBER_GOES_HERE\""/ settings.lua
sed -i  s/"splayd.settings.controller.ip = \"localhost\""/"splayd.settings.controller.ip = \"SPLAY_CTRL_IP\""/ settings.lua
sed -i s/print/--print/ settings.lua
sed -i s/os.exit/--os.exit/ settings.lua
sed -i s/"production = true"/"production = false"/ splayd.lua
cd ..
BASE=$1
SPLAYDS_PER_MACHINE=$2
SPLAY_CTRL_IP=$3
for ((i = 1 ; i <=$SPLAYDS_PER_MACHINE; i++ ))
do
  mkdir -p hosts/host_${BASE}_${i}
  cp -r template/* hosts/host_${BASE}_${i}
  sed s/NODE_NUMBER_GOES_HERE/${BASE}_${i}/ template/settings.lua > hosts/host_${BASE}_${i}/settings.lua
  sed -i  s/SPLAY_CTRL_IP/${SPLAY_CTRL_IP}/ hosts/host_${BASE}_${i}/settings.lua
done
for((j = 1 ; j <= $SPLAYDS_PER_MACHINE; j++))
do
  startport=$[12000+500*($j+1)]
  endport=$[$startport+499] #each splayd has 500 ports in range
  echo $startport $endport
  cd hosts/host_${BASE}_${j}/ 
  ctrlport=$[10999+$[$BASE % 10]] #first avail is 11000
  echo "Starting splayd host_${BASE}_${j} ${SPLAY_CTRL_IP} $ctrlport $startport $endport"
  lua splayd.lua host_${BASE}_${j} ${SPLAY_CTRL_IP} $ctrlport $startport $endport & 
  cd ../../;
  sleep 0.1
done
