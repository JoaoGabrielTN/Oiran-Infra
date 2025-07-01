trap parada SIGINT

WORKER_TOKEN=$(docker swarm join-token worker | grep SWMTKN)
MANAGER_TOKEN=$(docker swarm join-token manager | grep SWMTKN)
ADD_NODES=false

if [ "$(sudo virsh net-list --all | grep default)" == " default   inactive   yes         yes" ]; then
	echo "Iniciando a rede virtual Default\n"
	sudo virsh net-start default
fi
 
if [ "$(systemctl status docker | grep Active)" == "     Active: inactive (dead)" ]; then
	echo "Iniciando o serviço Docker\n"
	systemctl start docker
fi 

if [ "$(docker info | grep Swarm)" != " Swarm: active" ]; then
	echo "Ativando o Swarm\n"
	docker swarm init
fi

parada () {
	echo "Parando as VMs..."
	checar_status
	virsh shutdown asterix
	virsh shutdown getafix
	virsh shutdown obelix
	virsh shutdown dogmatix
	exit 0
}

ligar_vms () {
	virsh start asterix
	virsh start getafix
	virsh start obelix
	virsh start dogmatix
	checar_status
}

checar_status () {
	if [ "$(virsh dominfo asterix | grep State)" != "State:          shut off" ]; then
		while ! ssh -q asterix@192.168.122.200 "echo 'ASTERIX IS READY'"; do
			echo "Waiting for Asterix to start" 
			sleep 1
		done
	fi

	if [ "$(virsh dominfo getafix | grep State)" != "State:          shut off" ]; then
		while ! ssh -q getafix@192.168.122.150 "echo 'GETAFIX IS READY'"; do
			echo "Waiting for Getafix to start" 
			sleep 1
		done
	fi

	if [ "$(virsh dominfo obelix | grep State)" != "State:          shut off" ]; then
		while ! ssh -q obelix@192.168.122.100 "echo 'OBELIX IS READY'"; do
			echo "Waiting for Obelix to start" 
			sleep 1
		done
	fi

	if [ "$(virsh dominfo dogmatix | grep State)" != "State:          shut off" ]; then
		while ! ssh -q dogmatix@192.168.122.50 "echo 'DOGMATIX IS READY'"; do
			echo "Waiting for Dogmatix to start" 
			sleep 1
		done
	fi
}

join_swarm () { 
	if [ "$(virsh dominfo asterix | grep State)" == "State:          running" ]; then
		if  [ "$(ssh asterix@192.168.122.200 'docker info | grep Swarm')" != " Swarm: active" ]; then
			echo "Adicionando Asterix ao Swarm como um nó worker"
			ssh asterix@192.168.122.200 "docker swarm leave --force"
			ssh asterix@192.168.122.200 "$WORKER_TOKEN"
		fi
	fi
	
	if [ "$(virsh dominfo getafix | grep State)" == "State:          running" ]; then
		if  [ "$(ssh getafix@192.168.122.150 'docker info | grep Swarm')" != " Swarm: active" ]; then
			echo "Adicionando Getafix ao Swarm como um nó worker"
			ssh getafix@192.168.122.150 "docker swarm leave --force"
			ssh getafix@192.168.122.150 "$WORKER_TOKEN"
		fi
	fi

	if [ "$(virsh dominfo obelix | grep State)" == "State:          running" ]; then
		if  [ "$(ssh obelix@192.168.122.100 'docker info | grep Swarm')" != " Swarm: active" ]; then
			echo "Adicionando Obelix ao Swarm como um nó worker"
			ssh obelix@192.168.122.100 "docker swarm leave --force"
			ssh obelix@192.168.122.100 "$WORKER_TOKEN"
		fi
	fi

	if [ "$(virsh dominfo dogmatix | grep State)" == "State:          running" ]; then
		if  [ "$(ssh dogmatix@192.168.122.50 'docker info | grep Swarm')" != " Swarm: active" ]; then
			echo "Adicionando Dogmatix ao Swarm como um nó worker"
			ssh dogmatix@192.168.122.50 "docker swarm leave --force"
			ssh dogmatix@192.168.122.50 "$WORKER_TOKEN"
		fi
	fi
}

start_node_exporter () {
	ssh asterix@192.168.122.200 "node_exporter/node_exporter" &
	ssh getafix@192.168.122.150 "node_exporter/node_exporter" &
	ssh obelix@192.168.122.100 "node_exporter/node_exporter" &
	ssh dogmatix@192.168.122.50 "node_exporter/node_exporter" &
	
}

start_prometheus () {
	$HOME/oiran/prometheus/prometheus --config.file=prometheus/prometheus.yml &
}

main () {
	ligar_vms
	join_swarm
	start_node_exporter
	docker node ls
	start_prometheus
# 	parada

}

main
