# cloud-provision-vm

### Pre-requisitos

* Ter Credenciais AWS CLI para Criação de EC2 e recursos envolvidos
* Download do packer https://releases.hashicorp.com/packer/1.5.6/packer_1.5.6_linux_amd64.zip
* Descompactar packer_1.5.6_linux_amd64.zip
* Dar permissão de execução

### Como fazer

Execute no Shell

```
git clone https://github.com/antonionovaesjr/cloud-provision-vm.git
```

Faça as mudanças no install_docker.sh que achar necessário, depois execute

```
export AWS_ACCESS_KEY_ID=ABC
export AWS_SECRET_ACCESS_KEY=DEF
export AWS_DEFAULT_REGION=pais-regiao-numero
./packer build cloud-provision-vm/AWS/ec2-provision.json
```
Acompanhe a saida de log

### Depois de feito

Verifique se foi criado um EC2 na sua conta e uma imagem com o padrão de nome contigo no cloud-provision-vm/ec2-provision.json