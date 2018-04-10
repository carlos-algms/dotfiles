#!/usr/bin/perl -w

use utf8;

#print $#ARGV;
#print "\n";
#print " 1: $ARGV[0]\n";

if ($#ARGV < 0) {
  print "\nVoce deve passar o dominio completo: dominio.com.br para criar o DKIM.\n";
  exit;
}

sub dw
{
	if (@_)
	{
		print STDOUT $_[0] . "\n";
	}
}


# PERL MODULE
use Time::Piece;

my $date = Time::Piece->new->strftime('%d/%m/%Y %H:%M:%S');

dw("--- Inicio: $date ---");

my $TESTE = 0;



my $arquivo;
my $dominio 		= $ARGV[0];

my $dkimPath 		= ( $TESTE == 0 ? "/etc/opendkim" 			: "." );
my $keysPath 		= ( $TESTE == 0 ? $dkimPath."/keys"			: $dkimPath."" );
my $keyTableFile 	= ( $TESTE == 0 ? $dkimPath."/KeyTable"		: $dkimPath."/data.txt" );
my $signingTableFile= ( $TESTE == 0 ? $dkimPath."/SigningTable"	: $dkimPath."/data.txt" );

my $pastaDominio = $keysPath ."/".$dominio;


$erro = `mkdir "$pastaDominio" 2>&1`;

if( $? != 0 )
{
	dw("Erro ao criar a pasta: ". $erro);
	exit(1);
}

# criar as chaves na pasta do dominio
if( ! TESTE == 0 )
{
	`opendkim-genkey -d $dominio -s email -D "$pastaDominio"`;
}

# registrar a chave criada no arquivo do opendkim
open ($arquivo, ">>".$keyTableFile);
print $arquivo "email._domainkey.$dominio $dominio:email:$pastaDominio/email.private\n";
close($arquivo);


# registrar o dominio que poderá usar a chave criada
open ($arquivo, ">>".$signingTableFile);
print $arquivo "$dominio email._domainkey.$dominio\n";
close($arquivo);

# é necessário alterar o dono dos arquivos pois senão o opendkim dá não consegue ler.
`chown -R opendkim:opendkim $pastaDominio`;

# Reiniciar o servipo para ler as novas alterações.
`service opendkim restart`;

# exibir o registro TXT do DNS para não ter que dar outros comandos.
dw("\nRegistro TXT para o DNS:\n\n");

system("cat", $pastaDominio."/email.txt");

dw("\n\n");

$date = Time::Piece->new->strftime('%d/%m/%Y %H:%M:%S');

dw("--- Fim: $date ---\n");

exit(0);
