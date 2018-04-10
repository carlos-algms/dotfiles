#!/usr/bin/perl -w

use utf8;

# PERL MODULE
use DBI;

use Time::Piece;

my $date = Time::Piece->new->strftime('%d/%m/%Y %H:%M:%S');

print STDOUT "--- Inicio: $date ---\n";

# CONFIG VARIABLES
my $host 		= "127.0.0.1";
my $database 		= "postfix_db";
my $user 		= "postfix_udb";
my $pw 			= 'cb.postfix!14288';

my $MAILPROG 		= "/usr/sbin/sendmail -t";
my $VMAILDIR 		= "/home/vmail";
my $PORCENTOLIMITE	= 80;
my $ENVIAREMAIL		= 1;
my $EMAIL_FROM		= 'postmaster@cpro9647.publiccloud.com.br';

# PERL MYSQL CONNECT
#$connect = Mysql->connect($host, $database, $user, $pw);
my $connect = DBI->connect("DBI:mysql:$database;host=$host", $user, $pw);

my $sql = $connect->prepare('SELECT * FROM users_view') or die("Can't prepare: $connect->errstr\n");

$sql->execute() or die ("can't execute the query: $sql->errstr");

my $row;

my @usuariosLotando;

while( $row = $sql->fetchrow_hashref() )
{
	my @dadosUser	= split(/@/, $row->{email});
	
	my $limite = 0;
	my $usado = 0;
	my $firstLine = 0;


	my $user = {
		id 		=> $row->{id},
		nome 	=> $dadosUser[0],
		domain 	=> $dadosUser[1],
		usado 	=> 0
	};

	my $quotafile = "$VMAILDIR/$user->{domain}/$user->{id}/Maildir/maildirsize";

	# teste para verificar a montagem correta do path
	#print STDOUT "$quotafile\n\n";

	next unless (-f $quotafile);

	open(QF, "< $quotafile") or die $!;

	while(<QF>)
	{
		my $line = $_;

		if(! $firstLine) 
		{
			$firstLine = 1;
			die("Error: corrupt quotafile $quotafile") unless($line =~ /^(\d+)S/);
			$limite = $1;
			last if (! $limite);
			next;
		}

		die("Error: corrupt quotafile $quotafile") unless($line =~ /\s*(-?\d+)/);
		$usado += $1;
	}

	close(QF);

	next if (! $usado);

	$user->{usado} = int($usado / $limite * 100);

	print STDOUT "usado: $user->{usado}% | limite: $limite | ID: $user->{id} | nome: $user->{nome} | domain: $user->{domain}\n";

	if( $user->{usado} >= $PORCENTOLIMITE)
	{
		push(@usuariosLotando, $user);
		#print STDOUT "ID: $user->{id} | nome: $user->{nome} | domain: $user->{domain} | usado: $user->{usado}\n";
	}
}

$sql->finish();

if( $ENVIAREMAIL )
{
	print STDOUT "\n- Iniciando os envios.\n";

	foreach my $user (@usuariosLotando) 
	{
		print STDOUT "ID: $user->{id} | nome: $user->{nome} | domain: $user->{domain} | usado: $user->{usado}\n";

		open(MAIL, "| $MAILPROG");
		select(MAIL);
		print ("To: $user->{nome}@".$user->{domain}."\n");
		#map {print "BCC: $_\n"} @POSTMASTERS;
		print "From: $EMAIL_FROM\n";
		print "Subject: AVISO: seu e-mail está $user->{usado}% cheio.\n";
		print "Reply-to: $EMAIL_FROM\n";
		print "Seu e-mail: $user->{nome}@". $user->{domain} ." está $user->{usado}% cheio.\n\n";
		print "Assim que sua conta chegar a 100% você não conseguirá mais receber e-mails.\n";
		print "Por favor, apague os e-mails da sua lixeira, da pasta enviados e os spams.\n\n";
		#print "Qualquer dúvida, entre em contato com o administrador <$SUADDR>.\n\n";
		print "Qualquer dúvida, entre em contato com o administrador.\n\n";
		print "Obrigado.\n\n";
		print "--\n";
		#print "Administrador de e-mails\n";
		close(MAIL);

	}
}

#print STDOUT "\n---------------------------------\n\n";

$date = Time::Piece->new->strftime('%d/%m/%Y %H:%M:%S');

print STDOUT "--- Fim: $date ---\n\n";

exit(0);
