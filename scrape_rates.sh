#!/usr/bin/bash
source_file=""
curl_output="curl_output.txt"


get_mortgage_units()
{
asdasd
}




get_mortgage_rates()
{
echo "CreditUnion,Link,Rates"
for single_union in $(cat "${source_file}"|grep -vi best)
do
	rate_output=""
	union_name=$(echo "${single_union}"|cut -d, -f1)
	union_link=$(echo "${single_union}"|cut -d, -f2)
	curl -s $union_link > $curl_output
	#output=$(grep 'border="0"' $curl_output  | grep Today | sed 's/></>\n</g' |grep -E "productDetailsSamplePmt|Interest Rate"|sed 's/<\/a>//g;s/<\/td>//g'|rev|cut -d">" -f1|rev|sed 's/ //g' | paste -sd','|sed 's/Conforming,/Conforming|/g;s/Conforming1,/Conforming|/g;s/ARM,/ARM|/g')
	output=$(grep 'border="0"' $curl_output  | grep Today | sed 's/></>\n</g' |grep -E "productDetailsSamplePmt|Interest Rate"|sed 's/<\/a>//g;s/<\/td>//g'|rev|cut -d">" -f1|rev|sed 's/ //g'|sed 's/-/|/g' |paste -sd','|sed 's/|/-/g'|sed 's/%,/%|/g;s/,/#/g;s/|/,/g;s/#/|/g')
	if [[ -z "${output}" ]]; then
	output=$(cat $curl_output  | grep Today | sed 's/></>\n</g' |grep -E "productDetailsSamplePmt|Interest Rate"|sed 's/<\/a>//g;s/<\/td>//g'|rev|cut -d">" -f1|rev|sed 's/ //g'|sed 's/-/|/g' |paste -sd','|sed 's/|/-/g'|sed 's/%,/%|/g;s/,/#/g;s/|/,/g;s/#/|/g')	
	#output=$(cat $curl_output  | grep Today | sed 's/></>\n</g' |grep -E "productDetailsSamplePmt|Interest Rate"|sed 's/<\/a>//g;s/<\/td>//g'|rev|cut -d">" -f1|rev|sed 's/ //g' | paste -sd','|sed 's/Conforming,/Conforming|/g;s/Conforming1,/Conforming|/g;s/ARM,/ARM|/g')
	fi
	for single_output in $(echo "${output}"|sed 's/,/\n/g')
	do
		mortgage_program=$(echo "${single_output}"|cut -d"|" -f1|sed 's/-Conforming//g;s/-Conforming1//g')
		if [[ $(echo "${mortgage_program}" | grep -viE "20Year|FHA|15Year|30Year|VA|20Yr|15Yr|30Yr|10Yr|10Year") ]]; then
		      interest_rate=$(echo "${single_output}"|cut -d"|" -f2)
	              rate_output+=$mortgage_program-$interest_rate"|" 
                elif [[ $(echo "${mortgage_program}" |grep -vi "VA"| grep -E "30Year|30Yr") ]]; then 
		      interest_rate=$(echo "${single_output}"|cut -d"|" -f2)
		      rate_output+=$mortgage_program-$interest_rate"|"
		fi
	done
	[[ -z "${rate_output}" ]] && rate_output="None,"
        echo "$union_name,$union_link,$rate_output"|sed 's/.$//g'
done
}
