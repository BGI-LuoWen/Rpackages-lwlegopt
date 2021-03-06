#!/usr/bin/perl -w
use strict;
die"perl $0 <mutect> <samtools> <fasta> <96_mutation_types> <workdir> <title>\n"unless(@ARGV==6);
my($mut,$samtools,$fa,$mutation_types,$workdir,$title)=@ARGV;
open IN,"$mut" or die "$!";
open OUT,">$workdir/spectrum.txt";
my $coo=0;
while(<IN>){
  chomp;
  next if $_=~/^#/;
  if($_=~/^contig/){
     $coo=$coo+1;
     if($coo<2){
         print OUT "trinucleotides\tsubstitution\t$_\n";
     }
     next;
  }
  my($chr,$pos,$ref1,$obs1)=(split '\t',$_)[0,1,3,4];
  my $left=$pos-1;
  my $right=$pos+1;
  next if $chr=~/_/;
  next if $chr=~/chrM/;
  open LU,"$samtools faidx $fa  $chr:$left-$right|" or die"can not use samtools" ;
  my @sam=<LU>;
  close LU;
  chomp @sam;
  my $context=uc($sam[1]);
  if($ref1=~/G/){
     $ref1='C';    
     if($obs1=~/A/){
       $obs1='T';
     }elsif($obs1=~/T/){
       $obs1='A';
     }elsif($obs1=~/C/){
       $obs1='G';
     }elsif($obs1=~/G/){
       $obs1='C';
     }
     $context =~ tr/ATCG/TAGC/;
     my $d1= substr $context , 0 ,1;
     my $d2= substr $context , 1 ,1;
     my $d3= substr $context , 2 ,1;     
     $context=$d3.$d2.$d1;
  }
  if($ref1=~/A/){
     $ref1='T';
     if($obs1=~/A/){
       $obs1='T';
     }elsif($obs1=~/T/){
       $obs1='A';
     }elsif($obs1=~/C/){
       $obs1='G';
     }elsif($obs1=~/G/){
       $obs1='C';
     }
     $context =~ tr/ATCG/TAGC/;    
     my $d1= substr $context , 0 ,1;
     my $d2= substr $context , 1 ,1;
     my $d3= substr $context , 2 ,1;
     $context=$d3.$d2.$d1;
  }
    my $mm=$ref1.">".$obs1;
    print OUT "$context\t$mm\t$_\n";
}
close IN;
close OUT;
my %type;
open IN,"$mutation_types"or die "$!";
while(<IN>){
   chomp;
   my ($ty,$tr)=split '_',$_;
   $ty=~s/-/>/;
   my $d1=substr($tr,0,2);
   my $d2=substr($tr,4,1);
   $tr=$d1.$d2;
   $type{$ty}{$tr}=1;
}
close IN;
my %ksam;
my %data;
open IN,"$workdir/spectrum.txt";
open SM,">$workdir/sampleNames";
open SB,">$workdir/subtypes";
open TY,">$workdir/types";
open OR1,">$workdir/originalGenomes";
open OR2,">$workdir/originalGenomes_with_types.txt";
while(<IN>){
  chomp;
  next if $_=~/trinucleotides/;
  my($ttr,$tyr,$sam)=(split '\t',$_)[0,1,7];  
  $data{$tyr}{$ttr}{$sam}++;
  $ksam{$sam}=1;
}
close IN;
my @stype=("C>A","C>G","C>T");
my @stype1=("T>A","T>C","T>G");
my @sstype=('A_A','A_C','A_G','A_T','C_A','C_C','C_G','C_T','G_A','G_C','G_G','G_T','T_A','T_C','T_G','T_T');
my @sstype1=('ANA','ANC','ANG','ANT','CNA','CNC','CNG','CNT','GNA','GNC','GNG','GNT','TNA','TNC','TNG','TNT');
foreach my $tr(@stype){
   foreach my $tt(@sstype){
      $tt=~s/_/C/;
      print TY "$tr\n";
      print SB "$tt\n";
      my $str='';
      foreach my $samm(keys %ksam){
         if(exists $data{$tr}{$tt}{$samm}){
             $str.=$data{$tr}{$tt}{$samm}."\t";
         }else{
             $str.="0"."\t";
         } 
      }
      chop $str;
      print OR1 "$str\n";
      print OR2 "$tt\t$tr\t$str\n";
   }
}
foreach my $tr1(@stype1){
   foreach my $tt1(@sstype1){
      $tt1=~s/N/T/;
      print TY "$tr1\n";
      print SB "$tt1\n";
      my $str='';
      foreach my $samm(keys %ksam){
         if(exists $data{$tr1}{$tt1}{$samm}){
             $str.=$data{$tr1}{$tt1}{$samm}."\t";
         }else{
             $str.="0"."\t";
         } 
      }
      chop $str;
      print OR1 "$str\n";
      print OR2 "$tt1\t$tr1\t$str\n";
   }
}
foreach my $samm(keys %ksam){
   print SM "$samm\n";
}
close SM;
close SB;
close TY;
close OR1;
close OR2;
`cp $workdir/originalGenomes_with_types.txt $workdir/$title.originalGenomes_with_types.txt`;
