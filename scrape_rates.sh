#!/usr/bin/bash
source_file="$(dirname $(readlink -f $0))/credit_union.csv"
curl_output="$(dirname $(readlink -f $0))/curl_output.txt"
wget_output="$(dirname $(readlink -f $0))/credit_units.txt"
base_url="https://mortgages.cumortgage.net/start_up.asp"
siteid_url="https://mortgages.cumortgage.net/default.asp?siteId="
mortgage_rates="$(dirname $(readlink -f $0))/mortgage_rates.csv"

get_mortgage_units()
{
[[ -n start_up.asp ]] && rm -rf start_up.asp*
wget "${base_url}"
[[ -n start_up.asp ]] && cat start_up.asp| grep "option value="| grep -v 'option value="' > "${wget_output}"
for i in $(cat "${wget_output}"  |sed 's/> </>\n</g'|sed 's/<option //g;s/<\/option>//g;s/value=//g;s/ /-/g')
do 
sid=$(echo "${i}"|cut -d'>' -f1)
union_name=$(echo "${i}"|cut -d">" -f2|sed 's/-//g'|sed "s/,//g;s/\.//g;s/'//g"|sed 's/\r//g')
echo "$union_name,$siteid_url$sid"
done > "${source_file}"
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
	while ! grep -q "Today" $curl_output; do
 	curl -s $union_link > $curl_output
	sleep 5 # Wait for 5 seconds before checking again
	done
	output=$(grep 'border="0"' $curl_output  | grep Today | sed 's/></>\n</g' |grep -E "productDetailsSamplePmt|Interest Rate"|sed 's/<\/a>//g;s/<\/td>//g'|rev|cut -d">" -f1|rev|sed 's/ //g'|sed 's/-/|/g' |paste -sd','|sed 's/|/-/g'|sed 's/%,/%|/g;s/,/#/g;s/|/,/g;s/#/|/g')
	if [[ -z "${output}" ]]; then
	output=$(cat $curl_output  | grep Today | sed 's/></>\n</g' |grep -E "productDetailsSamplePmt|Interest Rate"|sed 's/<\/a>//g;s/<\/td>//g'|rev|cut -d">" -f1|rev|sed 's/ //g'|sed 's/-/|/g' |paste -sd','|sed 's/|/-/g'|sed 's/%,/%|/g;s/,/#/g;s/|/,/g;s/#/|/g')	
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

get_mortgage_units
get_mortgage_rates > "${mortgage_rates}"
rm -rf start_up.asp* $curl_output $credit_units $source_file