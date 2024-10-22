## Manipulação de Address Groups em firewalls Palo Alto

Este script nasceu de uma necessidade da necessidade de existir um serviço básico de balanceador de carga nos firewalls Palo Alto. Já existe o recurso de Address Grups, onde é possível usar o modo de endereço dinâmico. Porém, não há a opção de ter uma probe que valide se os serviços estão produtivos antes de encamnhar o tráfego.

Sendo assim, a ideia é utilizar este script com sua ferramenta de monitoramento e executá-lo de acordo com o status do seu serviço, removendo ou adicionando os hosts no grupo de endereços.

## Managing address groups in Palo Alto firewalls

This script has born from a need to exist a basic load balancer service in the firewalls of Palo Alto. There is already a address group, where is possible to use the dynamic address mode. However, there is no need to have a probe to check if the services are online before delivering traffic

Considering that, the idea is to use this script along with a monitoring tool and execute it depending on uour service status, removing or addind the hosts grom the address group dinamically.