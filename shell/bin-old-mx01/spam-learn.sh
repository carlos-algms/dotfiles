#!/bin/sh

#
# Armazenado em
# /root/scripts/spam-learn.sh
#

#run update every night
sa-update


PASTAVMAIL="/home/vmail"

COMMAND="/usr/bin/sa-learn --spam  "
#COMMAND="rm -v"

# path do arquivo de log
#ALOG="/var/log/mail.log"
ALOG="/var/log/spam-learn.log"

# esvaziar o arquivo de log
echo "" > ${ALOG}

# armazena o texto antes de escrever no arquivo de log para ficar tudo em série e nao misturar com os logs de outros apps
T=""

# marca par ir escrevendo direto no arquivo ao invez de armazenar na variavel e escrever só quando acabar
LOGAR_DIRETO=true

#nova linha no texto
NL="\r"

if ${LOGAR_DIRETO}; then
	NL=""
fi

Log() {
	if ${LOGAR_DIRETO}; then

		echo "${1} ${NL}" >> ${ALOG}

	else

		T="${T}${1}${NL}"

	fi
}


Log "----------------------------------------" 
Log "-- SISTEMA DE SPAM --"
Log "$(date)$NL$NL$NL"

cd $PASTAVMAIL

for dominio in $(ls -d */); do

	cd $dominio

	Log "====== Dominio: ${dominio} ======${NL}"

	#for caixa in $(ls -d */); do
	for caixa in $(find -maxdepth 1 -type d ! -iname ".*" ); do

		cd $caixa

		Log "${NL}== usuario: ${caixa}"

		Log "$(pwd)"

		if [ ! -d "Maildir" ]; then

			Log "usuário inválido, não possui a pasta Maildir"

		else

			cd "Maildir"

			if [ ! -d ".Spam" ]; then

				Log "Não tem a pasta .Spam"

			else

				$COMMAND "./.Spam/" | grep 'Learned' >> ${ALOG}

			fi

		fi

		cd "${PASTAVMAIL}/${dominio}"

    done # caixa

    Log "${NL}====== Fim do dominio: ${dominio} ====== ${NL}${NL}"

    cd "$PASTAVMAIL"

done # dominio

Log "-- FIM DO SISTEMA DE SPAM --"
Log "$(date)"
Log "----------------------------------------"
Log "${NL}${NL}"

if ! ${LOGAR_DIRETO} ; then 

	echo ${T} >> ${ALOG}

fi

#sa-learn --sync

exit 0

