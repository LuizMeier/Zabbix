:: Script para instalação dos agentes Zabbix Windows.
:: Luiz Fernando 4/7/2013

:: Cria os diretórios
mkdir c:\Zabbix
mkdir c:\Zabbix\conf
mkdir c:\Zabbix\bin
mkdir c:\Zabbix\logs

:: Diretório onde estão os executáveis e arquivos de configuração
set local="\\Share\caminho\"


::Verifica a arquitetura do servidor e copia o binario conforme a arquitetura
echo %PROCESSOR_ARCHITECTURE%
IF %PROCESSOR_ARCHITECTURE% EQU x86 (
        copy %local%\Agents\win32\* c:\zabbix\bin
) ELSE (
        copy %local%\Agents\win64\* c:\zabbix\bin
)

:: Copia a configuração padrão, onde nao inclui o hostname
copy %local%\Conf\zabbix_agentd.win.conf c:\zabbix\conf

:: Variavel que pega o nome do servidor e joga para o arquivo .conf
echo. >> c:\zabbix\conf\zabbix_agentd.win.conf
echo Hostname=%COMPUTERNAME%.dominio.lan >> c:\zabbix\conf\zabbix_agentd.win.conf

:: Variavel que pega o endereço IP do servidor e joga para o arquivo .conf
echo. >> c:\zabbix\conf\zabbix_agentd.win.conf
IPCONFIG |FIND "IP" > %temp%\TEMPIP.txt
FOR /F "tokens=2 delims=:" %%a in (%temp%\TEMPIP.txt) do set IP=%%a
del %temp%\TEMPIP.txt
set IP=%IP:~1%
echo ListenIP=%IP% >> c:\zabbix\conf\zabbix_agentd.win.conf

:: Configura o timeout
echo Timeout=10 >> c:\zabbix\conf\zabbix_agentd.win.conf

:: Instala o agent
c:\zabbix\bin\zabbix_agentd.exe -i -c c:\zabbix\conf\zabbix_agentd.win.conf

:: Inicia o serviço
C:\Zabbix\bin\zabbix_agentd.exe --start -c c:\Zabbix\conf\zabbix_agentd.win.conf