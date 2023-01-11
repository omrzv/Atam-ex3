#!/bin/bash

for f in *.zip
do
	NAME="${f%.*}"
	echo "Running ${NAME}"
	mkdir $NAME
	unzip -qq $NAME -d $NAME
	
	if [ -d "${NAME}/part1" ]; then
		cd $NAME
	elif [ -d "${NAME}/Part1" ]; then
		mv "${NAME}/Part1" "${NAME}/part1"
		if [ -d "${NAME}/Part2" ]; then
			mv "${NAME}/Part2" "${NAME}/part2"
		fi
		cd $NAME
	else
		mv "${NAME}.zip" "bad/${NAME}.zip"
		echo "ERROR in ${Name}"
		continue
	fi
	cd part1
	echo "Part 1:" 
	cp ../../elf64.h ./
	gcc -std=c99 hw3_part1.c -o prf &>/dev/null
	if [ -f "prf" ]; then
		cp prf ../../tests/part1/prf
		cd ../../tests/part1

		timeout 20s ./prf foo "test1.out" > studentout1.txt 2>/dev/null
		if [ $? -eq 0 ]; then
			diff part1_out_1.txt studentout1.txt &>/dev/null
			if [ $? -eq 0 ]; then
				echo -e "\tTest 1:\t\tPASS" 
			else
				echo -e "\tTest 1:\t\tFAIL - diff"
			fi
		else
			echo -e "\tTest 1:\t\tFAIL - Infinite loop / Exit status error" 
		fi
		
		timeout 20s ./prf sheldor "test1.out" > studentout2.txt 2>/dev/null
		if [ $? -eq 0 ]; then
			diff part1_out_2.txt studentout2.txt &>/dev/null
			if [ $? -eq 0 ]; then
				echo -e "\tTest 2:\t\tPASS" 
			else
				echo -e "\tTest 2:\t\tFAIL - diff" 
			fi
		else
			echo -e "\tTest 2:\t\tFAIL - Infinite loop / Exit status error" 
		fi
		
	sudo rm prf &>/dev/null
	cd ../../
	cd $NAME
	cd part1
	fi	
	cd ../part2
	echo -e "\n\nPart 2:"
	ld ../../tests/part2/a.o ../../tests/part2/b.o -T hw3_part2.ld -o ../../tests/part2/out
	cd ../../tests/part2

	if [ -f "out" ]; then
		
		readelf -h out | grep Entry > studentout1.txt 2>/dev/null
		diff studentout1.txt part2_out_1.txt &>/dev/null
		if [ $? -eq 0 ]; then
			echo -e "\tTest 1:\t\tPASS" 
		else
			echo -e "\tTest 1:\t\tFAIL" 
		fi
		
		readelf -Wl out | grep 0x0000000000400000 > studentout2.txt 2>/dev/null
		diff studentout2.txt part2_out_2.txt &>/dev/null
		if [ $? -eq 0 ]; then
			echo -e "\tTest 2:\t\tPASS" 
		else
			echo -e "\tTest 2:\t\tFAIL" 
		fi
	fi
	cd ../..
	sudo rm $NAME -rf
done
echo "END OF TEST"
