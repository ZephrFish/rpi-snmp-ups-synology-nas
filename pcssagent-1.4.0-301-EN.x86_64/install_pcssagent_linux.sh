#!/bin/sh 

######################################################################
# Exit Codes
######################################################################
EXIT_SUCCESS=0
EXIT_NOT_ROOT_USER=4
EXIT_USER_ABORT=7

clear

######################################################################
# Build Type
######################################################################
BUILD_TYPE=$(head -n 1 buildnumber.txt)

######################################################################
# Helper Functions
######################################################################

Print_RPM_Message() {   
	if [[ $LANG = en* ]]; then
		echo "PowerChute Serial Shutdown Agent could not be installed."
		echo "Errors occurred. Please check the log file rpm.log for more details."
	elif [[ $LANG = ja* ]]; then
		echo "PowerChute Serial Shutdownエージェントをインストールできませんでした。"
		echo "エラーが発生しました。詳細については、ログファイル rpm.log を確認してください。"
	elif [[ $LANG = zh* ]]; then
		echo "无法安装 PowerChute Serial Shutdown 代理。"
		echo "发生错误。有关更多详情，请查看日志文件 rpm.log。"
	fi
}

DisplayEULA(){
    
    EULA=""
    if [[ $BUILD_TYPE = *401 ]] || [[ $BUILD_TYPE = *501 ]]; then
        # Default to japanese license
        EULA="PCSS_EULA_Japanese.txt"
        AGREE="上記のライセンス条項に同意しますか？ [Y = はい/N = いいえ]"
        # Print the EULA to screen here
        more "EULA/$EULA"
    else
        until [ -n "$EULA" ]; do
		    # Display EULA
		    if [[ $LANG = en* ]]; then
			    printf "\nSelect EULA Language (Default: English) 1:English | 2:Deutsch | 3:Français | 4:Española | 5:中文 | 6:Bahasa Indonesia | 7:Italiano | 8:한국어 | 9:Português | 10:Română | 11:українська | 12:Türk\n"
		    elif [[ $LANG = zh* ]]; then
			    printf "\n选择 EULA 的语言（默认为英文） 1:English | 2:Deutsch | 3:Français | 4:Española | 5:中文 | 6:Bahasa Indonesia | 7:Italiano | 8:한국어 | 9:Português | 10:Română | 11:українська | 12:Türk\n"
		    fi
		
	        read reply
	
	        case "$reply" in
			    "" | 1 )
				    # Default to english license
				    EULA="PCSS_EULA_English.txt"		
				    AGREE="Do you agree to the above license terms? [yes or no]"
				    ;;
			    2) 
				    # Default to german license
				    EULA="PCSS_EULA_German.txt"		
				    AGREE="Stimmen Sie den oben genannten Lizenzbedingungen zu? [Y = Ja N = Nein]"
				    ;;
			    3) 
			   	    # Default to French license
				    EULA="PCSS_EULA_French.txt"		
				    AGREE="J’accepte par la présente le contrat de licence d’utilisateur final [Y = oui N = non]"
				    ;;
			    4) 
				    # Default to Spanish license
				    EULA="PCSS_EULA_Spanish.txt"		
				    AGREE="¿Está de acuerdo con los términos de licencia anteriores? [Y = sí N = no]"
				    ;;
			    5) 
				    # Default to Chinese license
				    EULA="PCSS_EULA_Chinese.txt"		
				    AGREE="您是否同意上述许可条款？[Y =是是N =否]"
				    ;;
			    6) 
				    # Default to Indnesian license
				    EULA="PCSS_EULA_Indonesian.txt"		
				    AGREE="Apakah Anda menyetujui ketentuan lisensi di atas? [Y = ya N = tidak]"
				    ;;
			    7) 
				    # Default to italian license
				    EULA="PCSS_EULA_Italian.txt"		
				    AGREE="Accetti le condizioni di licenza sopra indicate? [Y = yes N = no]"
				    ;;
			    8) 
				    # Default to korean license
				    EULA="PCSS_EULA_Korean.txt"		
				    AGREE="위의 라이센스 조항에 동의하십니까? [Y = 예 N = 아니오]";
			        ;;
			    9) 
				    # Default to portugeese license
				    EULA="PCSS_EULA_Portuguese.txt"		
				    AGREE="Você concorda com os termos de licença acima? [Y = sim N = não]"
				    ;;
			    10) 
				    # Default to romanian license
				    EULA="PCSS_EULA_Romanian.txt"		
				    AGREE="Sunteți de acord cu termenii de licență de mai sus? [Y = da N = nu]"
				    ;;
			    11) 
				    # Default to ukrainian license
				    EULA="PCSS_EULA_Ukrainian.txt"		
				    AGREE="Чи згодні ви з вищезазначеними умовами ліцензії? [Y = так N = ні]"
				    ;;
			    12) 
				    # Default to turkish license
				    EULA="PCSS_EULA_Turkish.txt"		
				    AGREE="Yukarıdaki lisans koşullarını kabul ediyor musunuz? [Y=Evet veya N= Hayır]"
				    ;;				
				
			    *)
				    # Invalid selection.  Go again...
				    EULA=""
				    if [[ $LANG = en* ]]; then
					    printf "\nInvalid selection.  Try again...\n"
				    elif [[ $LANG = ja* ]]; then
					    printf "\n選択が無効です。やり直してください...\n"
				    elif [[ $LANG = zh* ]]; then
					    printf "\n无效选择。请重试…\n"
				    fi
				    ;;
	        esac
        done
    
	# Print the EULA to screen here
    more "EULA/$EULA"
    fi
    agreed=
    while [ -z "$agreed" ]
    do
        printf "\n$AGREE\n"
        read reply leftover
        case $reply in
            [yY] | [yY][eE][sS])
                agreed=1
                ;;
            [nN] | [nN][oO])
				if [[ $LANG = en* ]]; then
					printf "If you don't agree to the license you can't install this software\n"
					printf "Aborting with error code-$EXIT_USER_ABORT\n"
				elif [[ $LANG = ja* ]]; then
					printf "ライセンスに同意しない場合は、このソフトウェアをインストールできません。\n"
					printf "エラーコード- で中止中$EXIT_USER_ABORT\n"
				elif [[ $LANG = zh* ]]; then
					printf "如果您不同意该许可，则无法安装此软件\n"
					printf "正在中止，错误代码-$EXIT_USER_ABORT\n"
				fi
                exit $EXIT_USER_ABORT
                ;;
            *)
				if [[ $LANG = en* ]]; then
					printf "Please enter \"yes\" or \"no\"."
				elif [[ $LANG = ja* ]]; then
					printf "\"yes\"または\"no\"を入力してください。"
				elif [[ $LANG = zh* ]]; then
					printf "请输入 \"yes\" 或 \"no\"。"
				fi
                ;;
        esac
     done
}

SelectInstallDir(){

	selectDir=
    while [ -z "$selectDir" ]
    do
        # Display Install Dir Options
		if [[ $LANG = en* ]]; then
			printf "\nInstall PowerChute into default directory $INSTALL_DIR? [yes or no]"
		elif [[ $LANG = ja* ]]; then
			printf "\nデフォルトディレクトリ $INSTALL_DIR に PowerChute をインストールしますか？[\"yes\"または\"no\"]"
		elif [[ $LANG = zh* ]]; then
			printf "\n是否将 PowerChute 安装到默认目录 $INSTALL_DIR？[\"yes\"或\"no\"]"
		fi
        read reply
        case $reply in
            [yY] | [yY][eE][sS])
                selectDir=1
                ;;
            [nN] | [nN][oO])
				if [[ $LANG = en* ]]; then
					printf "\nPlease enter the absolute path for the PowerChute installation\n"
				elif [[ $LANG = ja* ]]; then
					printf "\nPowerChute インストールの絶対パスを入力してください\n"
				elif [[ $LANG = zh* ]]; then
					printf "\n请输入安装 PowerChute 的绝对路径\n"
				fi
				read customDir
				INSTALL_DIR=$customDir
				selectDir=1
                ;;
            *)
				if [[ $LANG = en* ]]; then
					printf "Please enter \"yes\" or \"no\"."
				elif [[ $LANG = ja* ]]; then
					printf "\"yes\"または\"no\"を入力してください。"
				elif [[ $LANG = zh* ]]; then
					printf "请输入 \"yes\" 或 \"no\"。"
				fi
                ;;
        esac
    done
}

CheckUpgrade() {
	if rpm -q pbeagent > /dev/null 2>&1; then
		if [[ $LANG = en* ]]; then
			echo ""
			echo "Please uninstall PowerChute Business Edition before installing PowerChute Serial Shutdown."
			echo ""
			# printf "\nDo you want to upgrade PowerChute? [yes or no]"
		elif [[ $LANG = ja* ]]; then
			echo ""
			echo "PowerChute Serial Shutdownをインストールする前に、PowerChute Business Editionをアンインストールしてください。"
			echo ""
			# printf "\nPowerChute をアップグレードしますか？[\"yes\"または\"no\"]"
		elif [[ $LANG = zh* ]]; then
			echo ""
			echo "请先卸载PowerChute Business Edition，然后再安装PowerChute Serial Shutdown。"
			echo ""
			# printf "\n您要升级 PowerChute 吗？[\"yes\"或\"no\"]"
		fi
		exit 0
		
	elif rpm -q pcssagent > /dev/null 2>&1; then
		if [[ $LANG = en* ]]; then
			echo ""
			echo "PowerChute Serial Shutdown Agent is already installed."
			echo ""
			printf "\nDo you want to upgrade PowerChute? [yes or no]"
		elif [[ $LANG = ja* ]]; then
			echo ""
			echo "PowerChute Serial Shutdownエージェントは既にインストールされています。"
			echo ""
			printf "\nPowerChute をアップグレードしますか？[\"yes\"または\"no\"]"
		elif [[ $LANG = zh* ]]; then
			echo ""
			echo "PowerChute Serial Shutdown Agent 已安装。"
			echo ""
			printf "\n您要升级 PowerChute 吗？[\"yes\"或\"no\"]"
		fi
		
		 read reply
		 case $reply in
				[yY] | [yY][eE][sS])
					IS_UPGRADE=true
					;;
				[nN] | [nN][oO])
				if [[ $LANG = en* ]]; then
						echo "Aborting installation."
					elif [[ $LANG = ja* ]]; then
						echo "インストールを中止しています。"
					elif [[ $LANG = zh* ]]; then
						echo "中止安装。"
					fi
					
					exit 1
					;;
				*)
					if [[ $LANG = en* ]]; then
						printf "Please enter \"yes\" or \"no\"."
					elif [[ $LANG = ja* ]]; then
						printf "\"yes\"または\"no\"を入力してください。"
					elif [[ $LANG = zh* ]]; then
						printf "请输入 \"yes\" 或 \"no\"。"
					fi
					;;
			esac
	fi
}

######################################################################
# Main routine
######################################################################

ROOT="root"
USER=`id -nu`

INSTALL_DIR="/opt/APC/PowerChuteSerialShutdown/Agent"

if [ $USER != $ROOT ]; then
	if [[ $LANG = en* ]]; then
		echo "The installer must be run with root privileges."
		echo "Please run the installer as root or using sudo or su command."
		echo "Aborting with error code-$EXIT_NOT_ROOT_USER"
	elif [[ $LANG = ja* ]]; then
		echo "インストーラーは root 権限で実行しなければなりません。"
		echo "sudo または su コマンドを使用して、インストーラーを root 権限で実行してください。"
		echo "エラーコード- で中止中$EXIT_NOT_ROOT_USER"
	elif [[ $LANG = zh* ]]; then
		echo "安装程序必须采用根特权运行。"
		echo "请以根用户身份或使用 sudo 或 su 命令运行安装程序"
		echo "正在中止，错误代码-$EXIT_NOT_ROOT_USER"
	fi
    exit $EXIT_NOT_ROOT_USER
fi 

if [[ $LANG = en* ]]; then
	echo 
	echo "== PowerChute Serial Shutdown Agent Installation =="
	echo
	echo "For instructions on upgrading PowerChute, please refer to the install guide"
	echo
elif [[ $LANG = ja* ]]; then
	echo 
	echo "== PowerChute Serial Shutdownエージェントのインストール =="
	echo
	echo "PowerChute のアップグレード手順については、インストールガイドを参照してください。"
	echo
elif [[ $LANG = zh* ]]; then
	echo 
	echo "== PowerChute Serial Shutdown Agent 安装 =="
	echo
	echo "有关升级 PowerChute 的说明，请参阅安装指南"
	echo
fi


if [ -e /etc/rc.d/init.d/PowerChute -o -e /etc/init.d/PowerChute -o -e /usr/bin/PowerChute ]; then
	if [[ $LANG = en* ]]; then
		echo ""
		echo "############### ATTENTION ###############"
		echo "PowerChute Network Shutdown is installed. Please uninstall PowerChute Network Shutdown."
		echo "##########################################"
		echo ""
	elif [[ $LANG = ja* ]]; then
		echo ""
		echo "############### 注意 ###############"
		echo "PowerChute Network Shutdownがインストールされています。PowerChute Network Shutdownをアンインストールしてください。"
		echo "##########################################"
		echo ""
	elif [[ $LANG = zh* ]]; then
		echo ""
		echo "############### 注意 ###############"
		echo "已安装 PowerChute Network Shutdown。请卸载 PowerChute Network Shutdown。"
		echo "##########################################"
		echo ""
	fi
    exit 1
fi

DisplayEULA

IS_UPGRADE=false

CheckUpgrade

if [[ "$IS_UPGRADE" = false ]]; then
	SelectInstallDir

	echo 
	if [[ $LANG = en* ]]; then
		echo "Installing PowerChute Serial Shutdown Agent to $INSTALL_DIR ....."; 
	elif [[ $LANG = ja* ]]; then
		echo "PowerChute Serial Shutdownエージェントを $INSTALL_DIR にインストール中....."; 
	elif [[ $LANG = zh* ]]; then
		echo "正在将 PowerChute Serial Shutdown Agent 安装到 $INSTALL_DIR…"; 
	fi
	rpm -i --prefix=$INSTALL_DIR pcssagent-*.x86_64.rpm 1> /dev/null 2>./rpm.log

else
	echo 
	if [[ $LANG = en* ]]; then
		echo "Upgrading PowerChute Serial Shutdown Agent ....."; 
	elif [[ $LANG = ja* ]]; then
		echo "PowerChute Serial Shutdownエージェントのアップグレード中....."; 
	elif [[ $LANG = zh* ]]; then
		echo "正在升级 PowerChute Serial Shutdown Agent…"; 
	fi
	rpm -Uvh pcssagent-*.x86_64.rpm 1> /dev/null 2>./rpm.log
fi


# Note RPM scriptlet exit code is not persisted so $? always returns 1 on rpm failure
if [ "$?" -ne "0" ]; then
	Print_RPM_Message
	exit 1
fi	

if [[ $LANG = en* ]]; then
	echo "Installing PowerChute Serial Shutdown Agent ..... Complete"; 
	echo 
	if [[ "$IS_UPGRADE" = false ]]; then 
		echo "Executing PowerChute Serial Shutdown Agent configuration script ....." 
	fi
elif [[ $LANG = ja* ]]; then
	echo "PowerChute Serial Shutdownエージェントのインストール中.....完了"; 
	echo 
	if [[ "$IS_UPGRADE" = false ]]; then
		echo "PowerChute Serial Shutdownエージェント構成スクリプトの実行中....." 
	fi
elif [[ $LANG = zh* ]]; then
	echo "正在安装 PowerChute Serial Shutdown…完成"; 
	echo 
	if [[ "$IS_UPGRADE" = false ]]; then
		echo "正在执行 PowerChute Serial Shutdown Agent 配置脚本…" 
	fi
fi		

if [[ "$IS_UPGRADE" = false ]]; then
	cd $INSTALL_DIR 
	./config.sh $1
fi
break;
