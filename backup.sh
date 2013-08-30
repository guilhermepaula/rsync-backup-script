#/bin/bash
# Desenvolvido por:
# Hamacker <sirhamacker em gmail.com>
# Guilherme Paula <guilhermepaula em gmail.com>
# Licença: GNU/GPL 3

# Diretório que se deseja fazer backup
backup_origem="/home/$USER"
# Caso seja unidades remotas com o openssh-server instalado:
#backup_origem="root@192.168.1.2:/home/fulano"

# Arquivos com os arquivos para ignorar:
# ex:
# .recycle/*
# /Desktop/*
# /downloads/*
# *.log
backup_lista_negra="/home/$USER/outros/backup_script/backup_lista_negra.txt"

# se não existe, então criar:
if ! [ -e "$backup_lista_negra" ] ; then
   sudo touch $backup_lista_negra
fi

# Altere o uuid do disco destino:
# para saber, digite
# sudo vol_id --uuid /dev/sda1
backup_disco="c8c0a94d-b10e-41b1-a00b-06f07a78c9a2"
# se não existe, então avisar:
#if ! [ -e "/dev/disk/by-uuid/$backup_disco" ] ; then
#   echo "O disco [$backup_disco] não foi encontrado no sistema."
#   exit 2;
#fi

# Diretório onde esse disco está montado:
backup_montagem="/media/backup"

# se não existe, então criar:
if ! [ -d $backup_montagem ] ; then
  sudo mkdir -p $backup_montagem
fi

# subpasta para criar dentro do destino do backup:
# ex:
# Colocar cada backup mensal em uma pasta, AAAA-MM:
# backup_subpasta=”`date +%Y-%m`”
# 
# Colocar dentro da pasta meus backups:
# backup_subpasta=”meus_backups”
backup_subpasta="home"

# Não altere a linha abaixo:
backup_destino="$backup_montagem/$backup_subpasta"

# Tipo de partição usada no destino:
# ex:
# auto serve para ext2, ext3 e vfat
backup_particao="auto"

# Opções de montagem
# ex:
# async é mais rápido, porém no modo sync é mais confiável especialmente com pendrives.
backup_montagem_opcoes="async,rw,users"

# Montando a unidade de backup
sudo mount -t $backup_particao /dev/disk/by-uuid/$backup_disco $backup_montagem -o $backup_montagem_opcoes

# Logs das mudanças
# ex: no formato AAAA-MM-DD
logs="/home/$USER/outros/backup_script/logs/`date +%F`.log"

# Fazendo backup:
# -a: preserva características do arquivo (permissão, data/hora, etc)
# -v: modo verbose, exibe na tela mensagens do que está ocorrendo
# -P: modo parcial
# --delete: Deleta no destino caso não contenha mais na fonte
# -z: para fazer a compressão dos arquivos antes de enviar pela rede.
#     longos backups sem compressão pela rede é suicidio, especialmente
#     se houver usarios de sistema sistema remoto com ssh ou X.
# man rsync para mais opções
sudo rsync -avP --delete $backup_origem $backup_destino --exclude-from=$backup_lista_negra | tee $logs

# se houver erros, então:
if [ $? -ne 0 ] ; then
    echo “backup falhou totalmente ou parcialmente.”
fi

# desmontar unidade:
sudo umount $backup_montagem
if [ $? -ne 0 ] ; then
  # se nao desmontou da 1a tentativa, tentar de novo
  sudo umount $backup_montagem
  # se falhou na segunda tentativa entao é melhor avisar
  if [ $? -ne 0 ] ; then
    echo "Não foi possivel desmontar a unidade $backup_montagem"
    echo "Isso terá de ser feito manualmente."
  fi
fi
echo "Fim do backup"
