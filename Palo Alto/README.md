## Manipulação de Address Groups em firewalls Palo Alto

Este script nasceu de uma necessidade da necessidade de existir um serviço básico de balanceador de carga nos firewalls Palo Alto. Já existe o recurso de Address Grups, onde é possível usar o modo de endereço dinâmico. Porém, não há a opção de ter uma probe que valide se os serviços estão produtivos antes de encamnhar o tráfego.

Sendo assim, a ideia é utilizar este script com sua ferramenta de monitoramento e executá-lo de acordo com o status do seu serviço, removendo ou adicionando os hosts no grupo de endereços.
