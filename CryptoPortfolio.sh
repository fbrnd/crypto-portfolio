#!/bin/bash

# Required: install jq for json parsing

# ---------- API Key ----------

API_KEY="7ef05ccb-0c07-40bf-8c69-9563aeb57ad0"

# ---------- Color Variables ----------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
RESET='\033[0m'

# ---------- Create File ----------

check_file_function()
{
    FILE=data.csv
        if test -f "$FILE"; then
	    INPUT=data.csv
	    OLDIFS=$IFS
	    IFS=','

	else
	    touch ~/data.csv
	fi
}

# ---------- View Portfolio Function ----------

view_portfolio_function()
{
    clear 

    # ----- Sort Assets Alphabetically ----
    sort data.csv > tmp.csv	
    mv tmp.csv data.csv       

    # ----- Declare Total Value Arrary -----
    total_value_array=(0)

    # ----- Loop Asset, Balance File -----
    INPUT=data.csv
    OLDIFS=$IFS
    IFS=','

    while read asset balance
    do
        coin_price=$(curl -s -H 'X-CMC_PRO_API_KEY:'"$API_KEY" -H "Accept: application/json" -G\
        https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol="$asset" | jq '.data.'"$asset"'.quote.USD.price')
        coin_value=`echo $coin_price \* $balance | bc`

        # ----- Add Coin Value to Total Value Array -----
        total_value_array=(${total_value_array[@]} $coin_value)

        # ----- Create Temp File w/ Asset, Price, Balance, Value -----
        echo "$asset, $coin_price, $balance, $coin_value" >> tmp_file.csv

    done < $INPUT
    IFS=$OLDIFS

    # ----- Sum Total Value Array -----
    total_value=$( IFS="+"; bc <<< "${total_value_array[*]}" )

    # ----- Table Format -----
    separator=+--------------+-----------+----------------+------------+-------+
    rows="| %-13s|%10.2f |%15.8f |%11.2f |%6.1f |\n"
    TableWidth=70

    # ----- Top Separator -----
    printf "${CYAN}%.${TableWidth}s\n" "$separator"

    # ----- Table Headers -----
    printf "| %-13s|%10s |%15s |%11s |%6s |\n" Asset Price Balance Value %

    # ----- Separator -----
    printf "%.${TableWidth}s\n" "$separator"

    # ----- Loop Through temp_file.csv -----
    file=tmp_file.csv
    IFS=","

    while read asset price balance value
    do
        portfolio_percentage=`echo $value \/ $total_value \* 100 | bc -l`

         # ----- Display Assets in Table Row -----
        printf "${RESET}$rows" $asset $price $balance $value $portfolio_percentage

    done < $file
 
    # ----- End of Assets Separator -----
    printf "${GREEN}%.${TableWidth}s\n" "$separator"

    # ----- Total Value Table Row -----
    total_row="| %41s |%11.2f |%6s |\n"
    printf "$total_row" "Total" $total_value 100%

    # ----- Bottom Separator -----
    printf "%.${TableWidth}s\n" "$separator"

    # ----- Delete Temp File -----
    rm tmp_file.csv

    # ----- Store Total Value in CSV -----
    printf "$(date '+%F %T %Z'), " >> value.csv
    printf "%0.2f\n" $total_value >> value.csv

    printf "${RESET}\n"    
    display_menu_function
}

# ---------- Add Asset Function ----------

add_asset_function()
{
    clear

    printf "Enter Asset Symbol: "
    read asset_choice
    
    asset_to_add=$(curl -s -H 'X-CMC_PRO_API_KEY:'"$API_KEY" -H "Accept: application/json" -G\
    https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol="$asset_choice" | jq '.data.'"$asset_choice"'.quote.USD.price')

    # -- Check if asset is available --
    if [ "$asset_to_add" != "null" ]; then
        printf "How Many Coins?: "
        read balance_choice

	# -- Remove non numberical characters --
        edit=$(echo $balance_choice | sed 's/[^0-9.]*//g')

	# -- Check if input is blank --
	if [ -z "${edit}" ]; then
	    clear
            printf "${RED}Invalid Entry. Back to Menu${RESET}\n"
	    echo " "
            display_menu_function
	else
	    check=$(echo "$edit > 0" | bc)
		if [ $check -eq 1 ]; then
                    echo "$asset_choice, $edit"  >> data.csv
                    clear
            	    printf "${GREEN}$asset_choice successfully added!${RESET}\n"
                    echo " "
                    display_menu_function
         	else
	            printf "${RED}Invalid entry. Back to menu${RED}\n"
                    echo " "
	            display_menu_function
                fi	
        fi
    else
       clear
       printf "${RED}$asset_choice not found.${RESET}\n"
       echo " " 
       display_menu_function
    fi
}

# ---------- Remove Asset Function ----------
remove_asset_function()
{
    clear
    printf "Enter Asset Symbol to Remove: " 
    read remove_choice

    clear
    printf "Are you sure you want to remove $remove_choice? [y/n]: "
    read confirm_delete

    case $confirm_delete in

        y|Y|yes|Yes|YES)
            grep -v $remove_choice data.csv > tmp.csv
            mv tmp.csv data.csv
            
            clear
	    printf "${RED}$remove_choice Deleted${RESET}\n"
	    echo " "
	    display_menu_function
	    ;;
	*)
	    clear

	    printf "${GREEN}Back to Main Menu${RESET}\n"
	    echo " "

            display_menu_function
    esac
}

# ---------- Update Balance Function ----------
update_balance_function()
{
    clear

    printf "Enter asset to update: "
    read update_asset

    grep -v $update_asset data.csv > tmp.csv
    mv tmp.csv data.csv

    printf "Enter new balance: "
    read new_balance

    echo "$update_asset, $new_balance" >> data.csv
    
    clear
    printf "${GREEN}$update_asset balance is now $new_balance${RESET}\n"
    echo " "

    display_menu_function
}

# ---------- Menu ----------

display_menu_function()
{
    printf "==========================\n"
    printf "           Menu           \n"
    printf "==========================\n"
    printf "(1) View Portfolio\n"
    printf "(2) Add Asset\n"
    printf "(3) Remove Asset\n"
    printf "(4) Update Balance\n"
    printf "(5) Exit\n"
    printf  "\n "

    printf "Select [1-5]: "
    read menu_choice
    
    case $menu_choice in
	1)
            view_portfolio_function
            ;;
	2)
	    add_asset_function
            ;;
	3)
	    remove_asset_function
	    ;;
	4)
	    update_balance_function
	    ;;
        *)
	    clear
            ;;
    esac
}
# ======================================================
#                      Main Function 
# ======================================================

check_file_function	# Create data.csv file
clear
display_menu_function	# Display menu


