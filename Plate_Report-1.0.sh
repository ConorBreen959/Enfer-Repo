#!/bin/bash

# Authored by Ciarán and Conor

## Navigate to the directory containing the plate files.

cd A:/BioRad\ CFX\ Processing/BioRad\ Generated\ Files/Plate\ File/

## Function to change seconds to hours:minutes:seconds format.
function displaytime {
  local T=$1
  local H=$((T/60/60))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $H > 9 )) && printf '%d:' $H
  (( $H < 10 )) && printf '0%d:' $H
  (( $M > 9 )) && printf '%d:' $M
  (( $M < 10 )) && printf '0%d:' $M
  (( $S > 9 )) && printf '%d' $S
  (( $S < 10 )) && printf '0%d' $S
}

## Assign variable with yesterday's date in the ddmmyy format.
epoch_time=$(date +%s)
epoch_time_yesterday=$(($epoch_time-86400))
date_yesterday=$(date -d @$(echo $epoch_time_yesterday) +%d%m%y)
date_today=$(date -d @$(echo $epoch_time) +%d-%m-%y)

## Specify time to run Euroimmun and Altona assay in seconds.
euroimmun_time="5340"
altona_time="6360"





while true ; do
	## Restore cursor position to the position saved earlier. This resets every loop to overwrite existing lines instead of printing new ones.
	
	pcrd_temp=$(ls A:/BioRad\ CFX\ Processing/BioRad\ Generated\ Files/Data\ File/WIP)
	first_temp=$(ls A:/BioRad\ CFX\ Processing/BioRad\ Generated\ Files/Reports/00\ WIP/For\ eLIMS\ Import/)
	reported_temp=$(ls A:/BioRad\ CFX\ Processing/BioRad\ Generated\ Files/Reports/00\ WIP/For\ NVRL\ export/Reported/)
	interface_temp=$(curl -s http://172.16.52.68/processed_if4.php | grep $date_today | cut -c 9- | awk -F $"." 'BEGIN {OFS = FS} {print $1}' | sort -u)
	
	## Specify input field separator as newline \n in order to set each entire line from the ls pipeline as the variable $plate_inf.
	IFS=$'\n'
	
	## Open summary counters
	
	Not_read=0
	First_read=0
	Rep=0
	Still_on=0
	privs=0
	interface=0

	## Lists contents of "Plate File" folder containing the ddmmyy string of yesterday's date and sorts list by plate number.
	for plate_inf in $(stat -c "%n.%Y" *$date_yesterday* | awk '{print $1,$0}' | cut -c 4- | sort -n | cut -f2- -d' '); do
		
		## Reassign variables to continue updating times.
		epoch_time=$(date +%s)
		epoch_time_yesterday=$(($epoch_time-86400))
		date_yesterday=$(date -d @$(echo $epoch_time_yesterday) +%d%m%y)
		
		## Use tput to clear each line.
		tput el
		
		## Assign variables for epoch start time of plate and plate name without COV (e.g. 261120099).
		start_time=$(echo $plate_inf | awk -F $"." 'BEGIN { OFS = FS } {print $NF}')
		plate_name=$(echo $plate_inf | awk -F $"." 'BEGIN { OFS = FS } {print $1}' | cut -c 4-)
		
		## Find the time in seconds since the plate file was created.
		epoch_time_diff=$(($epoch_time-$start_time))
		
		## Check folders for .pcrd and .txt files.
		plate_name_wip_check=$(echo $pcrd_temp | grep $plate_name | wc -l)
		plate_name_1st_read=$(echo $first_temp | grep $plate_name | wc -l)
		plate_name_Reported=$(echo $reported_temp | grep $plate_name | wc -l)
		plate_name_interface=$(echo $interface_temp | grep $plate_name | wc -l)
		repeat_check=$(ls . | grep -iF $plate_name | wc -l)
				
		if [ $epoch_time_diff -ge $altona_time ] && [ $plate_name_wip_check -ne 0 ]; then
			if [ $repeat_check -ne 1 ]; then
				:
			elif [ $plate_name_Reported -ne 0 ] && [ $plate_name_interface -ne 0 ]; then
				echo -e "COV$plate_name\tReported ✔\tNVRL Interface ✔"
				interface=$((interface+1))
				Rep=$((Rep + 1))
			
			elif [ $plate_name_Reported -ne 0 ] && [ $plate_name_interface -eq 0 ]; then
				echo -e "COV$plate_name\tReported ✔\tNVRL Interface ✘"
				Rep=$((Rep + 1))
				
			elif [ $plate_name_1st_read -ne 0 ]; then
				private_check=$(head -n 2 A:/BioRad\ CFX\ Processing/BioRad\ Generated\ Files/Reports/00\ WIP/For\ eLIMS\ Import/COV$plate_name.txt | grep "99M"| wc -l)
				if [ $private_check -ne 0 ]; then
					echo -e "COV$plate_name\tPrivate Plate ✔"
					privs=$((privs + 1))
				else
					echo -e "COV$plate_name\t1st read ✔"
					First_read=$((First_read + 1))
				fi
				
			elif [ $plate_name_1st_read -eq 0 ] && [ $plate_name_Reported -eq 0 ]; then
				echo -e "COV$plate_name\tNot Read"
				Not_read=$((Not_read + 1))
				
			fi	
		#elif [ $epoch_time_diff -ge $euroimmun_time ] && [ $epoch_time_diff -lt $altona_time ] && [ $plate_name_wip_check -eq 0 ]; then
		#	altona_epoch_time_left=$(($altona_time-$epoch_time_diff))
		#	altona_time_left=$(displaytime $altona_epoch_time_left)
		#	Still_on=$((Still_on + 1))
		#	echo -e "COV$plate_name\tEuroimmun run time has elapsed but .pcrd not found in WIP folder, possible Altona run: $altona_time_left remaining."
		
		elif [ $epoch_time_diff -ge $altona_time ] && [ $plate_name_wip_check -eq 0 ]; then
			Still_on=$((Still_on + 1))
			echo -e "COV$plate_name\tEuroimmun and Altona run times have elapsed but .pcrd not found in WIP folder."
		
		else
			euroimmun_epoch_time_left=$(($euroimmun_time-$epoch_time_diff))
			euroimmun_time_left=$(displaytime $euroimmun_epoch_time_left)
			altona_epoch_time_left=$(($altona_time-$epoch_time_diff))
			altona_time_left=$(displaytime $altona_epoch_time_left)
			echo -e "COV$plate_name\tAltona: $altona_time_left remaining."
			Still_on=$((Still_on + 1))
		fi
	done
	## Print nicely formatted summary
	printf "\n"
	echo "Summary"
	printf "\n"
	echo -e "Privates:\t\t" $privs
	echo -e "1st Read:\t\t" $First_read
	echo -e "Reported:\t\t" $Rep
	echo -e "On NVRL Interface:\t" $interface
	echo -e "Still Running:\t\t" $Still_on
	echo -e "Total Read or Running:\t" $((privs+First_read+Rep+Still_on))
	echo -e "Not Read:\t\t" $Not_read
	printf "\n"
done


