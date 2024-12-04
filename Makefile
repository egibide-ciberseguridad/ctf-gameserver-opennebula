#!make

ifneq (,$(wildcard ./.env))
    include .env
    export
else
$(error No se encuentra el fichero .env)
endif

help: _header
	${info }
	@echo Opciones:
	@echo -----------------------------------------------------
	@echo build
	@echo init / plan / apply / show / output / destroy
	@echo -----------------------------------------------------
	@echo workspace
	@echo ssh [node=ctf-team-1]
	@echo -----------------------------------------------------
	@echo clean / clean-tfstate
	@echo nuke-apply
	@echo -----------------------------------------------------

_header:
	@echo ----------------------------
	@echo CTF Gameserver en OpenNebula
	@echo ----------------------------

build:
	@docker run --rm -v ./private:/private alpine /bin/sh -c 'touch /private/hosts'
	@docker compose build --pull

init:
	@docker run --rm -v ./private:/private alpine /bin/sh -c 'touch /private/hosts'
	@docker compose run --rm terraform-ansible generar_clave.sh
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform init -upgrade

plan:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform plan

provision-gameserver:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform apply -auto-approve -replace="null_resource.ansible_gameserver"

provision-node:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform apply -auto-approve -replace="null_resource.ansible_nodes[0]"

hosts:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform apply -auto-approve -replace="null_resource.hosts_gameserver" -replace="null_resource.hosts_haproxy"	-replace="null_resource.hosts_nodes[0]"

provision-sub:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform apply -auto-approve -replace="null_resource.ansible_subs[0]"

provision-haproxy:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform apply -auto-approve -replace="null_resource.ansible_haproxy"

apply:
	@docker compose run --rm terraform-ansible time -f "Tiempo total: %E" terraform -chdir=/terraform apply -auto-approve

show:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform show

output:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform output

destroy:
	@docker compose run --rm terraform-ansible time -f "Tiempo total: %E" terraform -chdir=/terraform destroy -auto-approve

workspace:
	@docker compose run --rm terraform-ansible

node?="ctf-gameserver"

ssh:
	@docker compose run --rm terraform-ansible run_ssh.sh $(node)

clean:
	@docker run --rm -v ./private:/private alpine /bin/sh -c 'rm -rf /private/*'
	@docker run --rm -v ./private:/private alpine /bin/sh -c 'touch /private/hosts'
	@docker compose down -t 0 -v --remove-orphans

clean-tfstate:
	@docker run --rm -v ./terraform:/terraform alpine /bin/sh -c 'rm -f /terraform/terraform.tfstate*'
	@docker run --rm -v ./terraform:/terraform alpine /bin/sh -c 'rm -rf /terraform/.terraform*'

nuke-apply: clean build init destroy apply
