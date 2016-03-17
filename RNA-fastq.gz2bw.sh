#!/bin/bash

help_info()
{
 echo -e "USAGE"
 echo -e "\t $0 -c <tophat command> -G <gtf file> -t <transcriptom> -n <num-threads> -z <cromsize> -x <index> -i <inputDir> -o <outputDir>"
}
while getopts :G:t:i:n:c:x:z:o: opt
do
case "$opt" in
G) echo "Found -G option"
   gtf=$OPTARG ;;
t) echo "Found -t option"
   transcriptom=$OPTARG ;;
i) echo "Found -i option"
   input=$OPTARG ;;
n) echo "Found -n option"
   threadsNum=$OPTARG ;;
c) echo "Found -c option"
   tophat=$OPTARG ;;
x) echo "Found -x option"
   index=$OPTARG ;;
z) echo "Found -z option"
   chromsize=$OPTARG ;;
o) echo "Found -z option"
   OutDir=$OPTARG ;;
*) echo "option or parameter Error"
   help_info ;;
 esac
done
#get dirname list
dir=`ls -l ${input}| grep ^d | awk '{print $9}'`

 for line in $dir;do
  # get filesname in each directory
  # files=`ls -l ${input}"/"${line} | grep ^- |awk '{print $9}' | sed "s@^@${input}/${line}/@g"| paste -s -d ","`
    files_1=`ls -l ${input}"/"${line} | grep _1.fastq.gz | awk '{print $9}' | sed "s@^@${input}/${line}/@g" | paste -s -d ","`
    files_2=`ls -l ${input}"/"${line} | grep _2.fastq.gz | awk '{print $9}' | sed "s@^@${input}/${line}/@g" | paste -s -d ","`
   echo ${line}
   echo ${files_1}
   echo ${files_2}
  # OutDir=${input}"/"${line}"/"tophat
    echo ${OutDir}
   Tophat=${OutDir}"/"Tophat
   if [ ! -d ${Tophat} ];then mkdir ${Tophat};fi
   ToGB=${OutDir}"/"ToGB 
   if [ ! -d $ToGB ];then mkdir $ToGB;fi
   mm10=${ToGB}"/"mm10
   if [ ! -d ${mm10} ];then mkdir ${mm10};fi
   logs=`dirname ${OutDir}`"/logs"
   tophat_log=${logs}"/tophat.log" 
   TophatDir=${Tophat}"/"${line}
   if [ ! -d ${TophatDir} ];then mkdir ${TophatDir};fi

   if [ ! -e ${tophat_log} ] || [ -z "`grep -i "Run complete" ${tophat_log}`" ];then
   
      ${tophat} --GTF ${gtf} --transcriptome-index ${transcriptom} --no-coverage-search --num-threads ${threadsNum} --output-dir ${TophatDir} ${index} ${files_1} ${files_2}
      echo `date` | tee -a ${logs}"/fastq2bw.log"
      echo ${input}"/"${line}" bamfile finished!" | tee -a ${logs}"/"fastq2bw.log
      if [ $? -ne 0 ];then
         echo ${line}" ERROR : tophat!" | tee -a ${logs}"/error.log"
         exit -1
      fi
   fi
   samtools sort ${TophatDir}"/"accepted_hits.bam ${ToGB}"/"sorted
      if [ -e ${ToGB}"/sorted.bam" ];then
         genomeCoverageBed -ibam ${ToGB}"/"sorted.bam -dz -split|awk '{print $1,$2,$2+1,$3}' > ${ToGB}"/"br
      else
          echo ${line}" ERROR : samtools sort!" | tee -a ${logs}"/error.log"
          exit -1
      fi
     

    bedGraphToBigWig ${ToGB}/br ${chromsize} ${mm10}"/"${line}.bw
if [ $? -eq 0 ];then
    rm ${ToGB}"/"sorted.bam ${ToGB}"/"br
else
echo "${line} failed!" | tee -a ${logs}"/error.log"
exit 2
 fi
track=${mm10}"/trackDb.txt"
echo "" >> ${track}
echo "track ${line}.bw" > ${track}
echo "type bigWig" >> ${track}
echo "bigDataUrl ${line}.bw" >> ${track}
echo "group PolyA_Seq" >> ${track}
echo "shortLabel ${line}.bw" >> ${track}
echo "longLabel ${line}.bw" >> ${track}
echo "visibility hide" >>${track}
echo "priority 1.28" >> ${track}
echo "autoScale on" >> ${track}
echo "yLineOnOff on" >> ${track}
echo "windowingFunction mean" >> ${track}
echo "" >> ${track}
echo "##################################" >> ${track}
genomes_file=${ToGB}"/genomes.txt"
echo "genome mm10" > ${genomes_file}
echo "trackDb mm10/trackDb.txt" >> ${genomes_file}


hub=${ToGB}"/hub.txt"
echo "hub ${line}.bw" > ${hub}
echo "shortLabel ${line}.bw" >> ${hub}
echo "longLabel ${line}.bw" >> ${hub}
echo "genomesFile genomes.txt" >> ${hub}
echo "email ${USER}_lilab@icsc.dlmedu.edu.cn" >> ${hub}
echo "descriptionUrl hub.html" >> ${hub}
done
